extends Object
class_name Binder

var event_callbacks = {}

func run_callbacks(event_name, data):
	if not event_name in event_callbacks: return
	if not event_callbacks[event_name] or event_callbacks[event_name].size(): return
	for event in event_callbacks[event_name]:
		if event.is_valid():
			event.call_func(data)

func bind(event_name, event_callback):
	if not event_name in event_callbacks:
		event_callbacks[event_name] = [event_callback]
	elif not event_callbacks[event_name].has(event_callback):
		event_callbacks[event_name].append(event_callback)

func unbind(event_name, event_callback = null):
	if event_name in event_callbacks:
		if not event_callback:
			event_callbacks.erase(event_name)
		else:
			event_callbacks[event_name].remove(event_callback)
