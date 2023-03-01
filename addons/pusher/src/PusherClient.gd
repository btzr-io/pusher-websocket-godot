tool
extends Node

# ----------
# Constants:
# ----------
#

const DESCRIPTION = "A Pusher Channels client addon for Godot"
const WARNING_MESSAGE_INVALID_CHANNEL = 'You are not subscribed to "{0}" channel: call .subscribe("{0}") first'
const WARNING_MESSAGE_CONFIGURATION = "To open a connection you must provide your app key and cluster name."

# --------------
# Configuration:
# --------------

## The app key for the application connecting to Pusher Channels
export var key = ""
## The name of the cluster that you’re using
export var cluster = ""
## The app secret key:
# Warning: Only use this for development and testing
export var secret = ""
## Connect on _ready otherwise use .connect_app
export var auto_connect = false

# Custom exports
var properties = []
var authentication_endpoint = ""
var authorization_endpoint = ""
var auth_params = {}
var auth_headers = {}

var user_auth_properties = [
	["authentication_endpoint", TYPE_STRING, authentication_endpoint]
]

var channel_auth_properties = [
	["authorization_endpoint", TYPE_STRING, authorization_endpoint],
]

# -----------
# Properties:
# -----------

# Internal properties:
var user
var socket_id
var channels = {}
var binder = Binder.new()
var connection = PusherConnection.new()
# Handle authentication / authorization
var auth = PusherAuth.new(self)

# Logger
var _log = null

func _logger(message):
	if _log and _log.is_valid():
		_log.call_func(message)

func property_can_revert(property):
	return property in Utils.get_props_names(properties) 

func property_get_revert(property):
	return Utils.get_default_prop_value(property, properties)

func _get_property_list():
	properties = []
	Utils.add_props_group("User Authentication", user_auth_properties, properties)
	Utils.add_props_group("Channel Authorization", channel_auth_properties, properties)
	return properties

func _is_valid():
	return  !auto_connect || key != "" and cluster != ""

func _enter_tree():
	editor_description = DESCRIPTION

func _get_configuration_warning() -> String:
	if !_is_valid():
		return WARNING_MESSAGE_CONFIGURATION
	return ""

# ---------------
# Initialization:
# ---------------

func _ready():
	if Engine.editor_hint: return
	
	if not _is_valid():
		push_warning(WARNING_MESSAGE_CONFIGURATION)
		return
	
	if auto_connect:
		connect_app()

func _process(_delta):
	if Engine.editor_hint: return
	if connection.state == PusherState.INITIALIZED: return
	if connection.state == PusherState.DISCONNECTED: return
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	connection.socket.poll()

# --------
# Methods:
# --------

func clear_properties():
	user = null
	channels = []
	socket_id = null
	binder.clear()

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
			authentication_endpoint = new_config["userAuthentication"]["endpoint"]

func connect_app(new_key = null, config = null):
	# Runtime configuration
	if new_key or config:
		configure(new_key, config)
	# Connect base signals to get notified of connection open, close, and errors.
	connection.socket.connect("connection_closed", self, "_closed")
	connection.socket.connect("connection_error", self, "_connection_error")
	connection.socket.connect("data_received", self, "_data")
	# Update connection state
	connection.state = PusherState.CONNECTING
	 # Open connection.
	var err = connection.start({"key": key, "cluster": cluster})
	if err != OK:
		connection.state = PusherState.UNAVAILABLE
		_error({ message = "Unable to connect" })
		set_process(false)
	else:
		set_process(true)

func disconnect_app():
	connection.socket.get_peer(1).close()

func channel(channel_name):
	if channel_name in channels:
		return channels[channel_name]
	else:
		push_warning(WARNING_MESSAGE_INVALID_CHANNEL.format([channel_name]))

func bind(event_name, event_callback):
	binder.bind(event_name, event_callback)

func unbind(event_name, event_callback = null):
	binder.unbind(event_name, event_callback)

func trigger(event, data = {}):
	connection.send_message({ "event": event, "data": data })
	_logger("Event sent -> " + event)

			
func subscribe(channel_name):
	var auth_data = {}
	var subscription = { "channel": channel_name }
	if not channel_name in channels:
		# Subscription requires authorization:
		if Utils.has_prefix(channel_name, ["private-", "presence-"]):
			if secret:
				auth_data = auth.authorize_channel_locally(channel_name)
				if "auth" in auth_data:
					subscription.merge(auth_data)
					trigger(PusherEvent.SUBSCRIBE, subscription)
					
			elif authorization_endpoint:
				var error = auth.authorize_channel(channel_name)
				if error:
					_error({ "message": "Failed authorization <- " + authorization_endpoint })
		else:
			# Subscribe to public channel
			trigger(PusherEvent.SUBSCRIBE, subscription)
		channels[channel_name] = PusherChannel.new(channel_name, self)
	if channel_name in channels:
		return channels[channel_name]

func unsubscribe(channel_name):
	if channel_name in channels:
		trigger(PusherEvent.UNSUBSCRIBE, { "channel": channel_name })
		channels.erase(channel_name)

# ---------------
# Event handlers:
# ---------------
 
func _signed(data):
	_logger("Authentication ready: " +  str(data) )

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	connection.state = PusherState.DISCONNECTED
	clear_properties()
	set_process(false)
	_logger("Closed, clean: " + str(was_clean))

func _connected(data):
	socket_id = data["socket_id"]
	connection.state = PusherState.CONNECTED
	_logger("Connection established: " + JSON.print(data))

func _connection_error():
	connection.state = PusherState.UNAVAILABLE
	_error({ message = "Unable to connect" })

func _error(data):
	push_error("Pusher error: " + data.message)
	
func _subscribed(channel, data):
	_logger("Subscribed to channel: " + channel)

		
func _data():
	var data
	var event
	var channel
	var message = connection.get_message()
	var connection_state = connection.state 
	
	if message and message.has("data"):
		data = message["data"]

	if message and message.has("event"):
		event = message["event"]
		if PusherEvent.is_protocol_event(event):
			event = event.replace("pusher_internal:", "pusher:")
		
	if message and message.has("channel"):
		channel = message["channel"]
	
	if not event: return
	
	# Log pusher protocol events:
	_logger("Event received <- " + event)
		
	match event:
		PusherEvent.ERROR:
			_error(data)
		PusherEvent.SIGNIN_SUCCESS:
			_signed(data)
		PusherEvent.CONNECTION_ESTABLISHED:
			_connected(data)
		PusherEvent.SUBSCRIPTION_SUCCEEDED:
			_subscribed(channel, data)
	
	# Run binded connection protocol events:
	if PusherEvent.is_protocol_event(event):
		# Remove protocol schema
		var connection_event = PusherEvent.get_name(event)
		connection.binder.run_callbacks(connection_event)
		
	# Run binded connection events:
	if connection_state != connection.state:
		connection.binder.run_callbacks(connection.state)

	# Run binded events on all channels
	binder.run_callbacks(event, data)
	
	if channel in channels:
		# Run channel binded events
		channels[channel].binder.run_callbacks(event, data)
