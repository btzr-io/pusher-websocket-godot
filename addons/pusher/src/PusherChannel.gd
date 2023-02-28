extends Object
class_name PusherChannel

var name = ""
var client = null
var binder = Binder.new()

func _init(channel_name, channel_client):
	name = channel_name
	client = channel_client

func bind(event_name, event_callback):
	binder.bind(event_name, event_callback)

func unbind(event_name, event_callback = null):
	binder.unbind(event_name, event_callback)

func unsubscribe():
	client.unsubscribe(name)
	
func trigger(event_name, data):
	if client.connection:
		 if event_name.begins_with("client-"):
				if name.begins_with("private-") or name.begins_with("presence-"):
					client.connection.send_message({
						"data": data,
						"event": event_name,
						"channel": name
					})
					client._logger("Channel event sent to #" + name + ": "  + event_name)

