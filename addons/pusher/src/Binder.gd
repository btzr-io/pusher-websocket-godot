extends Object
class_name Binder

var events = []

func clear():
	events = []

func find_match(event, event_name, method, channel = null):
	if event["name"] == event_name:
		if channel and event["channel"] != channel:
			return false
		if typeof(event["method"]) == typeof(method):
			return event["method"] == method
	return false

func bind_event(event_name, method, channel = null):
	for event in events:
		if find_match(event, event_name, method, channel): return
	events.append({"name": event_name, "method": method, "channel": channel })
	
func unbind_event(event_name, method, channel = null):
	for index in events.size():
		var event = events[index]
		if find_match(event, event_name, method, channel):
			return events.remove(index)
					
func run(event_name, channel, data):
	if not events or not events.size(): return
	for event in events:
		if event["name"] == event_name:
			if channel:
				if event["channel"] == channel:
					if event["method"].is_valid():
						event["method"].call_func(data)
			else:
				if event["method"].is_valid():
					event["method"].call_func(data)
