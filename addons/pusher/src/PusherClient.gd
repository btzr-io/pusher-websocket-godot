tool
extends Node

# ----------
# Constants:
# ----------
#

#const Utils = preload("Utils.gd")
#const Binder = preload("Binder.gd")
#const PusherAPI = preload("PusherAPI.gd")
#const PusherChannel = preload("PusherChannel.gd")

const DESCRIPTION = "A Pusher Channels client addon for Godot"
const CONFIGURATION_WARNING_MESSAGE = "To open a connection you must provide your app key and cluster name."

# --------
# Signals:
# --------

signal error(error_data)
signal connected(connection_data)
signal state_changed(new_connection_state)

# --------------
# Configuration:
# --------------

## The app key for the application connecting to Pusher Channels
export var key = ""
## The name of the cluster that you’re using
export var cluster = ""
## Connect on _ready otherwise use .connect_app
export var auto_connect = false

# Custom exports
var properties = []
## Authenticate on connection_stablished otherwise use signing()
var auto_signin = false
## Authentication endpoint
var auth_endpoint = ""
var auth_params = {}
var auth_headers = {}

var auth_properties = [
	[ "auto_signin", TYPE_BOOL, auto_signin],
	[ "auth_endpoint", TYPE_STRING, auth_endpoint],
]

# -----------
# Properties:
# -----------

# Internal properties:
var pusher
var socket_id
var user_data
var connection_url
var connection_state = PusherAPI.STATE.INITIALIZED setget set_connection_state
var channels = {}
var authenticated = false
var binder = Binder.new()

func property_can_revert(property):
	return property in Utils.get_props_names(properties) 

func property_get_revert(property):
	return Utils.get_default_prop_value(property, properties)

func _get_property_list():
	properties = []
	Utils.add_props_group("User Authentication", auth_properties, properties)
	return properties

func _is_valid():
	return  !auto_connect || key != "" and cluster != ""

func _enter_tree():
	editor_description = DESCRIPTION

func _get_configuration_warning() -> String:
	if !_is_valid():
		return CONFIGURATION_WARNING_MESSAGE
	return ""


# ---------------
# Initialization:
# ---------------

func _ready():
	if Engine.editor_hint: return
	
	if not _is_valid():
		push_warning(CONFIGURATION_WARNING_MESSAGE)
		return
	
	if auto_connect:
		connect_app()

func _process(_delta):
	if Engine.editor_hint: return
	if connection_state == PusherAPI.STATE.INITIALIZED: return
	if connection_state == PusherAPI.STATE.DISCONNECTED: return
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	pusher._client.poll()

# --------
# Methods:
# --------

func clear_properties():
	pusher = null
	channels = []
	socket_id = null
	user_data = null
	authenticated = false
	connection_url = null
	binder.clear()

func set_connection_state(value):
	connection_state = value
	emit_signal("state_change")
	print_debug("Connection state changed to: ", value)

func configure(new_key = null, new_config = null):
	if not new_key and not new_config: return
	# App key
	if new_key and new_key != "":
		key = new_key
	# Cluster name
	if new_config and new_config.has("cluster"):
		cluster = new_config["cluster"]
	# Authentication configuration
	if new_config and new_config.has("userAuthentication"):
		if new_config["userAuthentication"].has("params"):
			auth_params = new_config["userAuthentication"]["params"]
		if new_config["userAuthentication"].has("headers"):
			auth_headers = new_config["userAuthentication"]["headers"]
		if new_config["userAuthentication"].has("endpoint"):
			auth_endpoint = new_config["userAuthentication"]["endpoint"]

func connect_app(new_key = null, config = null):
	# Runtime configuration
	if new_key or config:
		configure(new_key, config)
	# Creare websocket client	
	pusher = PusherAPI.new({"key": key, "cluster": cluster})
	# Expose connection url
	connection_url = pusher._websocket_url
	# Connect base signals to get notified of connection open, close, and errors.
	pusher._client.connect("connection_closed", self, "_closed")
	pusher._client.connect("connection_error", self, "_connection_error")
	pusher._client.connect("data_received", self, "_data")
	# Update connection state
	connection_state = PusherAPI.STATE.CONNECTING
	 # Initiate connection to the given URL.
	var err = pusher.init_connection()
	if err != OK:
		connection_state = PusherAPI.STATE.UNAVAILABLE
		_error({ message = "Unable to connect" })
		set_process(false)
	else:
		signin()
		set_process(true)

func disconnect_app():
	pusher._client.get_peer(1).close()

func signin(params={}, headers={}):
	if authenticated: return
	if !auth_endpoint: return
	Utils.post_request(self, "_auth_requested", auth_endpoint, params, headers)

func bind(event_name, event_callback):
	binder.bind(event_name, event_callback)

func unbind(event_name, event_callback):
	binder.unbind(event_name, event_callback)

func trigger(event, data = {}):
	pusher.send_message({ "event": event, "data": data })
	print_debug("Protocol event sent: ", event)

func subscribe(channel_name):
	if not channel_name in channels:
		trigger(PusherAPI.SUBSCRIBE, { "channel": channel_name })
		channels[channel_name] = PusherChannel.new(channel_name, self)
		return channels[channel_name]

func unsubscribe(channel_name):
	if channel_name in channels:
		trigger(PusherAPI.UNSUBSCRIBE, { "channel": channel_name })
		channels.remove(channel_name)

# ---------------
# Event handlers:
# ---------------
 
func _signed(data):
	user_data = data
	authenticated = true
	print_debug("Authentication ready: ", data)

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	connection_state = PusherAPI.STATE.DISCONNECTED
	clear_properties()
	set_process(false)
	print_debug("Closed, clean: ", was_clean)

func _connected(data):
	socket_id = data["socket_id"]
	connection_state = PusherAPI.STATE.CONNECTED
	emit_signal("connected", data)
	print_debug("Connected: ", socket_id)

func _connection_error():
	connection_state = PusherAPI.STATE.UNAVAILABLE
	_error({ message = "Unable to connect" })

func _error(data):
	emit_signal("error")
	push_error("Pusher error: " + data.message)
	
func _subscribed(channel, data):
	print_debug("Subscribed to channel: ", channel)

func _internal_subscribed(channel):
	print_debug("Subscribed to channel: ", channel)

func _auth_requested(result: int, response_code: int, headers, body):	
	if result != HTTPRequest.RESULT_SUCCESS or response_code > 200:
		return push_error("Authentication request failed: " + auth_endpoint)
	if body:
		trigger(PusherAPI.SIGNIN, { "auth": "", "user_data": {} })
	
func _data():
	var data
	var event
	var channel
	var message = pusher.get_message()

	if message and message.has("data"):
		data = message["data"]

	if message and message.has("event"):
		event = message["event"]
		print_debug("Protocol event received: ", event)

	if message and message.has("channel"):
		channel = message["channel"]
	
	if not event: return
	
	match event:
		PusherAPI.ERROR:
			_error(data)
		PusherAPI.SIGNIN_SUCCESS:
			_signed(data)
		PusherAPI.CONNECTION_ESTABLISHED:
			_connected(data)
		PusherAPI.SUBSCRIPTION_SUCCEEDED:
			_subscribed(channel, data)
		PusherAPI.INTERNAL_SUBSCRIPTION_SUCCEEDED:
			_internal_subscribed(channel)
		_:
			if not channel:
				# Run protocol binded events
				binder.run_callbacks(event, data)
			else:
				# Run channel binded events
				channels[channels].run_callbacks(event, data)
