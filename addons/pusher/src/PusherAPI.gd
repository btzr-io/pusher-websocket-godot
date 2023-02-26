extends Object
class_name PusherAPI

# Configuration
const SCHEME = "wss"
const PROTOCOL = "7"
const ENDPOINT = "pusher.com:443/app"
const FORMAT_URL = "{SCHEME}://ws-{CLUSTER}.{ENDPOINT}/{KEY}?{PARAMS}"
const DEFAULT_PARAMS = {"key": "", "cluster": ""}

# Events:
# Connection events:
const PING = "pusher:ping"
const PONG = "pusher:pong"
const ERROR = "pusher:error"
const CONNECTION_ESTABLISHED = "pusher:connection_established"
# Authentication events:
const SIGNIN = "pusher:signin"
const SIGNIN_SUCCESS = "pusher:signin_success"
# Subscription events:
const SUBSCRIBE = "pusher:subscribe"
const UNSUBSCRIBE = "pusher:unsubscribe"
const SUBSCRIPTION_ERROR = "pusher:subscription_error"
const SUBSCRIPTION_SUCCEEDED = "pusher:subscription_succeeded"
const INTERNAL_SUBSCRIPTION_SUCCEEDED = "pusher_internal:subscription_succeeded"


# Connection states
enum STATE {
	FAILED
	CONNECTED,
	CONNECTING,
	INITIALIZED,
	UNAVAILABLE,
	DISCONNECTED
}

# Properties
var _client
var _pusherData
var _websocket_url

func _init(data = DEFAULT_PARAMS):
	if data and data.has_all(DEFAULT_PARAMS.keys()):
		# store data
		_pusherData = data
		# Create client
		_client = WebSocketClient.new()
		# Create connection url
		_websocket_url = _create_url()

func _create_url():
	return FORMAT_URL.format({
		"KEY": _pusherData["key"],
		"SCHEME": SCHEME,
		"PARAMS": "protocol=" + PROTOCOL,
		"CLUSTER": _pusherData["cluster"],
		"ENDPOINT": ENDPOINT
	})

func init_connection():
	if _client and _websocket_url:
		_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
		return _client.connect_to_url(_websocket_url)

func send_message(data):
	var raw_data = data
	raw_data = JSON.print(raw_data).to_utf8()
	_client.get_peer(1).put_packet(raw_data)

func get_message():
	var raw_data = _client.get_peer(1).get_packet().get_string_from_utf8()
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
