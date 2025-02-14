extends Object
class_name PusherEvent

# ------------------
# Connection events:
# ------------------

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
const SUBSCRIPTION_COUNT = "pusher:subscription_count"
const SUBSCRIPTION_SUCCEEDED = "pusher:subscription_succeeded"
const PROTOCOL_SCHEMA = "pusher:"

static func is_protocol_event(event_name : String):
	return PusherUtils.has_prefix(event_name, ["pusher:", "pusher_internal:"])

static func get_event_name(event_name : String):
	if event_name.begins_with(PROTOCOL_SCHEMA):
		return event_name.replace(PROTOCOL_SCHEMA, "")
	return event_name
