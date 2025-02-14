extends Object
class_name PusherChannel

var name : String = ""
var client : Variant =  null
var binder : PusherBinder = PusherBinder.new()

signal event

func _init(channel_name, channel_client) -> void:
	name = channel_name
	client = channel_client
	client.event.connect(_handle_event)

func bind(event_name, event_callback):
	binder.bind(event_name, event_callback)

func unbind(event_name, event_callback = null):
	binder.unbind(event_name, event_callback)
	
func _handle_event(event_data) -> void:
	if event_data.channel == name and 'event' in event_data:
		event.emit(event_data)
		binder.run_callbacks(event_data.event, event_data)

func unsubscribe() -> void:
	client.unsubscribe(name)
	client.event.disconnect(_handle_event)
	
func trigger(event_name : String, data : Variant = {}) -> void:
	if client.connection:
		if event_name.begins_with("client-"):
			if name.begins_with("private-") or name.begins_with("presence-"):
				var event_data : Dictionary = {
					"data": data,
					"event": event_name,
					"channel": name
				}
				client.connection.send_message(event_data)
				client._logger("Event sent " + event_name + " -> #" + name )
