tool
extends Node

# Constants:
const Utils = preload("Utils.gd")
const PusherAPI = preload("PusherAPI.gd")
const PusherChannel = preload("PusherChannel.gd")
const CONFIGURATION_WARNING_MESSAGE = "To open a connection you must provide your app key and cluster name."

# Signals:
signal error(error_data)
signal connected(connection_data)
signal state_changed(new_connection_state)

## The app key for the application connecting to Pusher Channels
export var key = ""
## The name of the cluster that you’re using
export var cluster = ""
## Connect on _ready otherwise use .connect_app
export var auto_connect = true

# Internal properties:
var pusher
var socket_id
var user_data
var connection_url
var connection_state = PusherAPI.STATE.INITIALIZED setget _set_connection_state
var channels = []
var authenticated = false

# External properties 4:
var properties = []

## User authentication options:
## Authenticate on connection_stablished otherwise use signing()
var auto_signin = true
## Authentication endpoint
var auth_endpoint = "http://localhost:800/pusher"

var auth_properties = [
	[ "auto_signin", TYPE_BOOL, auto_signin],
	[ "auth_endpoint", TYPE_STRING, auth_endpoint],
]

func property_can_revert(property):
	return property in Utils.get_props_names(properties) 

func property_get_revert(property):
	return Utils.get_default_prop_value(property, properties)

func _get_property_list():
	properties = []
	Utils.add_props_group("Authentication", auth_properties, properties)
	return properties

func _set_connection_state(value):
	connection_state = value
	emit_signal("state_change")
	print_debug("Connection state changed to: ", value)

func _is_valid():
	return  key != "" and cluster != ""

func _enter_tree():
	editor_description = "A Pusher Channels client addon for Godot"

func _get_configuration_warning() -> String:
	if key == "" or cluster == "":
		return CONFIGURATION_WARNING_MESSAGE
	return ""

func _ready():
	if Engine.editor_hint: return
	
	if not _is_valid():
		push_warning(CONFIGURATION_WARNING_MESSAGE)
		return
	
	if auto_connect:
		connect_app()

func connect_app():
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
		set_process(false)
		_error({ message = "Pusher error: Unable to connect" })
	else:
		signin()
		set_process(true)

func disconnect_app():
	# Close connection
	pusher._client.get_peer(1).close()
	# Reset props
	pusher = null
	channels = []
	socket_id = null
	user_data = null
	authenticated = false
	connection_url = null

func signin(params={}, headers={}):
	if authenticated: return
	Utils.post_request(self, "_auth_requested", auth_endpoint, params, headers)

func trigger(event, data = {}):
	pusher.send_message({ "event": event, "data": data })
	print_debug("Protocol event sent: ", event)
	
func trigger_channel(channel, event, data = {}):
	pusher.send_message({ "channel": channel, "event": event, "data": data })
	print_debug("Protocol event sent: ", event)

func subscribe(channel_name):
	trigger(PusherAPI.SUBSCRIBE, { "channel": channel_name })

func unsubscribe(channel_name):
	trigger(PusherAPI.UNSUBSCRIBE, { "channel": channel_name })

func _signed(data):
	user_data = data
	authenticated = true
	print_debug("Authentication ready: ", data)

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	connection_state = PusherAPI.STATE.DISCONNECTED
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

func _process(delta):
	if Engine.editor_hint: return
	if connection_state == PusherAPI.STATE.INITIALIZED: return
	if connection_state == PusherAPI.STATE.DISCONNECTED: return
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	pusher._client.poll()
