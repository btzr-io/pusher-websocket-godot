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
var state = -1
var last_state
# Our WebSocketClient instance.
var socket = WebSocketPeer.new()

# Signals:
signal message_received(message: Variant)
signal connection_opened
signal connection_closed

# --------
# Methods:
# --------
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
		return socket.connect_to_url(url)

func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()

	state = socket.get_ready_state()

	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connection_opened.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
	while socket.get_ready_state() == socket.STATE_OPEN and socket.get_available_packet_count():
		var message =  get_message()
		if message and message is Dictionary:
			message_received.emit(message)

func send_message(data):
	var raw_data = data
	raw_data = JSON.stringify(raw_data).to_utf8_buffer()
	socket.put_packet(raw_data)

func get_message():
	var raw_data = socket.get_packet().get_string_from_utf8()
	var message = JSON.new()
	var error = message.parse(raw_data)
	
	if error == OK:
		message = message.data
	else:
		message = error
		
	if typeof(message) == TYPE_DICTIONARY:
		if message:
			if message.has("data"):
				var data = message["data"]
				if typeof(data) == TYPE_STRING:
					var result = PusherUtils.parse_json(data)
					if typeof(result) == TYPE_DICTIONARY:
						message["data"] = result
		return message
	# Failed to parse message
	push_error("Unexpected results.")
