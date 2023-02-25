extends Object
class_name Utils

static func get_props_names(props):
	var names = []
	for prop in props:
		if prop.type != TYPE_NIL:
			names.append(prop.name)
	return names

static func add_props_group(group_name, new_props, props):
	# Add group separator
	props.append({
		type = TYPE_NIL,
		name = group_name,
		usage = PROPERTY_USAGE_CATEGORY
	})
	# Add group properties
	for  prop in new_props:
		props.append({ name = prop[0], type = prop[1], default = prop[2] })

static func get_default_prop_value(prop_name, props):
	for prop in props:
		if prop.name == prop_name:
			return prop.default

static func parse_headers(headers):
	var results = []
	var keys = headers.keys()
	var values = headers.values()
	for index in headers:
		results.append(keys[index] + ": " + str(values[index]))
	return results
	
static func post_request(context, on_completed, endpoint, params, headers):
	var http_request = HTTPRequest.new()
	http_request.timeout = 5
	context.add_child(http_request)
	# Connect signals
	http_request.connect("request_completed", context, on_completed)
	# Perform a POST request
	var body = to_json(params)
	var error = http_request.request(endpoint, parse_headers(headers), true, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request: " + endpoint)
