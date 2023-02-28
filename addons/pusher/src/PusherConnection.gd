extends Object
class_name PusherConnection

# -------------
# Configuration
# -------------

const SCHEME = "wss"
const PROTOCOL = "7"
const ENDPOINT = "pusher.com:443/app"
const FORMAT_URL = "{SCHEME}://ws-{CLUSTER}.{ENDPOINT}/{KEY}?{PARAMS}"
const REQUIRED_PARAMS = {"key": "", "cluster": ""}

var url : String
var options : Dictionary
var state = PusherState.INITIALIZED setget set_connection_state
var binder = Binder.new()
var socket = WebSocketClient.new()

# --------
# Methods:
# --------
	
func set_connection_state(value):
	state = value

func _create_url():
	return FORMAT_URL.format({
		"KEY": options["key"],
		"SCHEME": SCHEME,
		"PARAMS": "protocol=" + PROTOCOL,
		"CLUSTER": options["cluster"],
		"ENDPOINT": ENDPOINT
	})

func start(connection_options):
	if not connection_options: return
	if connection_options.has_all(REQUIRED_PARAMS.keys()):
		# store data
		options = connection_options
		# Create connection url
		url = _create_url()
	if socket and url:
		socket.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
		return socket.connect_to_url(url)

func bind(connection_state, callback):
	binder.bind(connection_state, callback)

func unbind(connection_state, callback = null):
	binder.unbind(connection_state, callback)

func send_message(data):
	var raw_data = data
	raw_data = JSON.print(raw_data).to_utf8()
	socket.get_peer(1).put_packet(raw_data)

func get_message():
	var raw_data = socket.get_peer(1).get_packet().get_string_from_utf8()
	var message = JSON.parse(raw_data).result
	if typeof(message) == TYPE_DICTIONARY:
		if message:
			if message.has("data"):
				var data = message["data"]
				if typeof(data) == TYPE_STRING:
					var result = JSON.parse(data).result
					if typeof(result) == TYPE_DICTIONARY:
						message["data"] = result
		return message
	# Failed to parse message
	push_error("Unexpected results.")
