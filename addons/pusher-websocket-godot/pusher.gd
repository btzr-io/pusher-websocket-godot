extends Node
# ----------
# Constants:
# ----------
#
const WARNING_MESSAGE_INVALID_CHANNEL = 'You are not subscribed to #"{0}" channel: call .subscribe("{0}") first'
const WARNING_MESSAGE_CONFIGURATION = "To open a connection you must provide your app key and cluster name."
const WARNING_MESSAGE_MISSING_ENDPOINT = "To subscribe to a private or presence channel you must provide an authorization enpoint."
const KEEP_ALIVE_TIME = 15.0 # seconds
const RECONNECTION_DELAY = 15.0 # seconds
enum RECONNECT { DELAY, IMMEDIATELY }

# --------------
# Configuration:
# --------------
## Enable debug mode:
var debug : bool = false
## The app key for the application connecting to Pusher Channels
var key : String = ""
## The name of the cluster that you’re using
var cluster : String = ""
## The app secret key:
# Warning: Only use this for development and testing
var secret : String
var authentication_endpoint : String = ""
var authorization_endpoint : String = ""
var auth_params = {}
var auth_headers = {}

# -----------
# Properties:
# -----------

# Internal properties:
var user : Variant
var socket_id : Variant
var binder : PusherBinder
var channels: Dictionary = {}
var connection : PusherConnection = PusherConnection.new()
var connection_state : String = PusherState.INITIALIZED :
	set(value):
		connection_state = value
		connection_state_changed.emit(value)
# Handle authentication / authorization
var auth : PusherAuth = PusherAuth.new(self)
# Cache data
var _cache_connection_error : Variant
var _cache_connection_state : String = connection_state
# Signals
signal event(event_data)
signal connection_error(error_data)
signal connection_established(event_data)
signal connection_state_changed(connection_state)
signal signin_failed(error_data)
signal signin_success(event_data)
signal subscription_succeded(channel_name, event_data)

func _logger(message):
	if debug:
		print_rich("[color=cyan](PUSHER)[/color] " + message)

func _process(delta):
		# Alert connection state changes:
	if _cache_connection_state != connection_state:
		_cache_connection_state = connection_state
		_logger("Connection state changed: [b]" + connection_state + "[/b]")
	# Can't open connection
	if connection_state == PusherState.FAILED: return
	# No connection is open yet:
	if connection_state == PusherState.INITIALIZED: return
	# Server or client diconnected:
	if connection_state == PusherState.DISCONNECTED: return
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	connection.poll()

# --------
# Methods:
# --------

func bind(event_name, event_callback):
	binder.bind(event_name, event_callback)

func unbind(event_name, event_callback = null):
	binder.unbind(event_name, event_callback)

func clear_properties():
	user = null
	binder = null
	socket_id = null
	channels = {}
	connection = PusherConnection.new()

func configure(new_key = null, new_config = null):
	if not new_key and not new_config: return
	# App key
	if new_key and new_key != "":
		key = new_key
	# Secret
	if new_config and new_config.has("secret"):
		secret = new_config["secret"]
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
	if !new_key or !config or !config['cluster']:
		_warning(WARNING_MESSAGE_CONFIGURATION)
		return

	if connection_state == PusherState.CONNECTING: return
	# Runtime configuration
	if new_key or config:
		configure(new_key, config)
	# Update connection state
	connection_state = PusherState.CONNECTING
	# Connect base signals to get notified of connection open, close, and errors.
	PusherUtils.connect_signal(connection.message_received, _data)
	PusherUtils.connect_signal(connection.connection_closed, _closed)
	PusherUtils.connect_signal(connection_error, _connection_error)
	# Create binder
	binder = PusherBinder.new()
	# Open connection.
	var err = connection.start({"key": key, "cluster": cluster})
	if err != OK:
		_connection_error()


func disconnect_app():
	_cache_connection_error = null
	connection.socket.disconnect_from_host()

func reconnect(mode):
	if mode == RECONNECT.IMMEDIATELY:
		_logger("Retry connection...")
		connect_app()
	if mode == RECONNECT.DELAY:
		await get_tree().create_timer(RECONNECTION_DELAY).timeout
		_logger("Retry connection...")
		connect_app()

func get_channel(channel_name: String) -> PusherChannel:
	if channel_name in channels:
		return channels[channel_name]
	return null

func signin():
	if secret:
		auth.authenticate_user_locally()
	else:
		auth.authenticate_user()

func trigger(event, data = {}):
	connection.send_message({ "event": event, "data": data })
	_logger("Event sent: [b]" + event + "[/b]")

func subscribe(channel_name):
	var auth_data = {}
	var subscription = { "channel": channel_name }
	if not channel_name in channels:
		# Subscription requires authorization:
		if PusherUtils.has_prefix(channel_name, ["private-", "presence-"]):
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
				_warning(WARNING_MESSAGE_MISSING_ENDPOINT)
				_error({ "message": "Failed channel subscription: #" + channel_name })
		else:
			# Subscribe to public channel
			trigger(PusherEvent.SUBSCRIBE, subscription)
		channels[channel_name] = PusherChannel.new(channel_name, self)
	
	return get_channel(channel_name)

func unsubscribe(channel_name):
	if channel_name in channels:
		trigger(PusherEvent.UNSUBSCRIBE, { "channel": channel_name })
		channels.erase(channel_name)

# ---------------
# Event handlers:
# ---------------
 
func _signed(data):
	user = data
	signin_success.emit(data)
	_logger("Authentication ready: " +  PusherUtils.to_json(data) )

func _closed(was_clean = false):
	if not _cache_connection_error:
		clear_properties()
		connection_state = PusherState.DISCONNECTED
	else:
		connection_state = PusherState.UNAVAILABLE

func _connected(data):
	socket_id = data["socket_id"]
	connection_state = PusherState.CONNECTED
	connection_established.emit(data)
	_logger("Connection established: " + PusherUtils.to_json(data))

func _connection_error():
	connection_state = PusherState.UNAVAILABLE
	reconnect(RECONNECT.DELAY)

func _warning(message):
	push_warning("PUSHER_WARNING: " + message)
	
func _error(data):
	if "message" in data and data["message"]:
		push_error("PUSHER_ERROR: " + data["message"])
	if "code" in data and data["code"]:
		# Cache current error
		_cache_connection_error = data
		if (data["code"] >= 4000) and (data["code"] <= 4099):
			# The connection SHOULD NOT be re-established unchanged
			disconnect_app()
		elif (data["code"] >= 4100) and (data["code"] <= 4199):
			# The connection SHOULD be re-established after backing off
			reconnect(RECONNECT.DELAY)
		elif (data["code"] >= 4200) and (data["code"] <= 4299):
			# The connection SHOULD be re-established immediately
			reconnect(RECONNECT.IMMEDIATELY)
			
func _subscribed(channel, data: Dictionary):
	subscription_succeded.emit(channel, data)
	_logger("Subscribed to channel #" + channel)
	
func _data(message):
	var data
	var channel
	var event_name

	if message and message.has("data"):
		data = PusherUtils.parse_json(message["data"])
		if "user_data" in data:
			data = PusherUtils.parse_json(data["user_data"])
			
	if message and message.has("event"):
		event_name = message["event"]
		if PusherEvent.is_protocol_event(event_name):
			event_name = event_name.replace("pusher_internal:", "pusher:")
	
	if message and message.has("channel"):
		channel = message["channel"]
	
	if not event_name: return
	
	event.emit({"event": event_name, "data": data, "channel": channel})
	binder.run_callbacks(event_name, data)
	
	# Log pusher protocol events:
	_logger("Event received: [b]" + PusherEvent.get_event_name(event_name) + "[/b]")

	match event_name:
		PusherEvent.ERROR:
			_error(data)
		PusherEvent.SIGNIN_SUCCESS:
			_signed(data)
		PusherEvent.CONNECTION_ESTABLISHED:
			_connected(data)
		PusherEvent.SUBSCRIPTION_SUCCEEDED:
			_subscribed(channel, data)
