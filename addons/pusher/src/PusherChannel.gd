extends Object
class_name PusherChannel

var name = ""
var auth = null
var connection = null
var binder = Binder.new()

func _init(channel_name, channel_connection):
	name = channel_name
	connection = channel_connection

func bind(event_name, event_callback):
	binder.bind(event_name, event_callback)

func unbind(event_name, event_callback):
	binder.unbind(event_name, event_callback)
	
func trigger(event_name, data):
	if connection:
		 if event_name.begins_with("client-"):
				if name.begins_with("private-") or name.begins_with("presence-"):
					connection.send_message({
						"data": data,
						"event": event_name,
						"channel": name
					})
					print_debug("Channel event sent: @", name, " : ", event_name)

