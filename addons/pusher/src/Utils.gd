extends Object
class_name Utils

static func has_prefix(text, prefixes):
	for prefix in prefixes:
		if text.begins_with(prefix):
			return true
	return false

static func hmac_hex_digest(key, format_string, format_params):
	var crypto = Crypto.new()	
	var message = format_string.format(format_params)
	var token = crypto.hmac_digest(HashingContext.HASH_SHA256, key.to_utf8(), message.to_utf8())
	return token.hex_encode()
	
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
	for index in keys.size():
		results.append(keys[index] + ": " + str(values[index]))
	return results

static func get_root():
	return Engine.get_main_loop().get_root()

static func post_request(context, endpoint, callback, params = {}, headers = {}):
	var body = to_json(params)
	var http_request = HTTPRequest.new()
	get_root().add_child(http_request)
	# Perform a POST request
	http_request.timeout = 5.0
	http_request.connect("request_completed", context, callback, [params])
	var error = http_request.request(endpoint, parse_headers(headers), true, HTTPClient.METHOD_POST, body)
	if error: http_request.cancel_request()
	return error
		

# uuid - static uuid generator for Godot Engine:
# https://github.com/binogure-studio/godot-uuid/blob/master/LICENSE
# Note: The code might not be as pretty it could be, since it's written
# in a way that maximizes performance. Methods are inlined and loops are avoided.

const MODULO_8_BIT = 256

static func getRandomInt():
  # Randomize every time to minimize the risk of collisions
  randomize()
  return randi() % MODULO_8_BIT

static func uuidbin():
  # 16 random bytes with the bytes on index 6 and 8 modified
  return [
	getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
	getRandomInt(), getRandomInt(), ((getRandomInt()) & 0x0f) | 0x40, getRandomInt(),
	((getRandomInt()) & 0x3f) | 0x80, getRandomInt(), getRandomInt(), getRandomInt(),
	getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
  ]

static func uuid():
  # 16 random bytes with the bytes on index 6 and 8 modified
  var b = uuidbin()
  return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
	# low
	b[0], b[1], b[2], b[3],
	# mid
	b[4], b[5],
	# hi
	b[6], b[7],
	# clock
	b[8], b[9],
	# clock
	b[10], b[11], b[12], b[13], b[14], b[15]
  ]
