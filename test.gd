extends Node2D

var channel
var on_log = funcref(self, "logger")
var on_signin = funcref(self, "handle_signin")
var on_event = funcref(self, "handle_event")
var on_connected =  funcref(self, "handle_connected")
var on_subscription = funcref(self, "handle_subscription")

func _ready():
	$Pusher._log = on_log
	$Pusher.connection.bind(PusherState.CONNECTED, on_connected)
	# $Pusher.connect_app()
	
func logger(message):
	print(message)
	
func handle_subscription(_data):
	channel.bind("client-hello", on_event)
	channel.trigger("client-hello", { "message": "ok!!!" })

func handle_signin(_data):
	channel = $Pusher.subscribe("presence-channel-lobby")
	channel.trigger("data")
	channel.bind(PusherEvent.SUBSCRIPTION_SUCCEEDED, on_subscription)

func handle_event(data):
	print("data: ", data)


func handle_connected(_data):
	$Pusher.signin()
	$Pusher.bind(PusherEvent.SIGNIN_SUCCESS, on_signin)
