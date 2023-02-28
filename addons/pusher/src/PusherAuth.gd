extends Object
class_name PusherAuth

var client

func _init(auth_client):
	client = auth_client

static func get_user_auth_token(key, secret, socket_id, user_data):
	var user = JSON.print(user_data)
	var signature = Utils.hmac_hex_digest(secret, "{0}::user::{1}", [socket_id, user])
	return "{0}:{1}".format([key, signature])

static func get_private_auth_token(key, secret, socket_id, channel):
	var signature = Utils.hmac_hex_digest(secret, "{0}:{1}", [socket_id, channel])
	return "{0}:{1}".format([key, signature])

static func get_presence_auth_token(key, secret, socket_id, channel, user_data):
	var user = JSON.print(user_data)
	var signature = Utils.hmac_hex_digest(secret, "{0}:{1}:{2}", [socket_id, channel, user])
	return "{0}:{1}".format([key, signature])

# Local authorization:
# Warning: Only use this for development and testing
func authorize_channel_locally(channel_name):
	if not client.secret: return {}
	# Generate private channel authorization
	if channel_name.begins_with("private-"):
			var auth = get_private_auth_token(
				client.key,
				client.secret,
				client.socket_id,
				channel_name
			)
			return { "auth": auth }
	# Generate presence channel authorization
	if channel_name.begins_with("presence-"):
		# Generate random user data
		var user_data = {"user_id": Utils.uuid()}
		var auth = get_presence_auth_token(
				client.key,
				client.secret,
				client.socket_id,
				channel_name,
				user_data
		)
		return { "auth": auth, "channel_data": JSON.print(user_data) }
	# Failed authorization
	return {}

func authorize_channel(channel_name):
	if not Utils.has_prefix(channel_name, ["private-", "presence-"]): return {}
	# Both channel types require socket_id and channel_name:
	var auth_body = {
		"scoket_id": client.socket_id,
		"channel_name": channel_name
	}
	# Presence channels requires additional data:
	# if channel_name.begins_with("presence-"): 
	# Remote autorization:
	return Utils.post_request(
		self,
		client.authorization_endpoint,
		"_authorization",
		auth_body
	)

func _authorization(error, code, headers, body, params):
	if error or code != 200 or not body or not params or not "channel_name" in params:
		client._error({ "message": "Failed authorization <- " + client.authorization_endpoint })
	else:
		var auth_data = JSON.parse(body.get_string_from_utf8())
		if auth_data.error:
			client._error({ "message": "Failed authorization <- " + client.authorization_endpoint })
		elif auth_data.result:
			var subscription = { "channel": params["channel_name"] }
			subscription.merge(auth_data.result)
			client.trigger(PusherConnection.SUBSCRIBE, subscription)
