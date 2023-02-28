# :rocket: Pusher Channels ( client addon )

A [Pusher Channels](https://pusher.com/channels) client  addon for [Godot](https://github.com/godotengine/godot).

Create real-time interactions with the [Pusher Channels Protocol](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/) over a [WebSocket connection](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html).

## Table of Contents
- [Installation](#installation)
- [Quick start](#quick-start)
  - [Open a connection](#open-a-connection)
  - [Listen for events](#listen-for-events)
  - [Subscribe to a channel](#subscribe-to-a-channel)
- [Configuration](#configuration)
    - [Options](#options)
       - [UserAuthentication](#userauthentication)
       - [ChannelAuthorization](#userauthentication)
    - [Loggin](#loggin)
- [Connection](#configuration)
  - [Disconnect](#disconnect)
- [Channels](#channels)
  - [Subscribing to channels](#subscribing-to-channels)
  - [Unsubscribing from channels](#unsubscribing-from-channels)
  - [Accessing channels](#accessing-channels)
- [Binding to events](#binding-to-events)
  - [Event callback](#event-callback)
  - [Binding on the client](#binding-on-the-client)
  - [Unbinding from events](#unbinding-from-events)
  
## Installation
Move the [./addons](https://github.com/btzr-io/pusher-websocket-godot/tree/main/addons/) folder into your project folder.

See full guide: [Installing a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)


## Quick start
Enable the plugin and add a `Pusher` node to your main scene.

See full guide: [Enabling a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#enabling-a-plugin)


### Open a connection
```swift
$Pusher.connect_app( APP_KEY, { "cluster": APP_CLUSTER } )
```

### Listen for events:
```swift
func event_handler(data):
  print("Event received")
  
var callback = funcref(self, "event_handler")

$Pusher.bind("pusher:connection_established", callback);

```

### Subscribe to a channel
```swift
$Pusher.subscribe("channel-name")
```



## Configuration

It is possible to set and update the client configuration through the `configure` method:

```swift
$Pusher.configure(KEY, OPTIONS)
```

Params of the `configure` method:

| Param            | Type         | description             |
|------------------|--------------|-------------------------|
| key              | string       | The [application key](https://pusher.com/docs/channels/using_channels/connection/#applicationkey-2105278448)     |
| options          | dictionary   | See [below](#options)   |

### Options:

Based on Pusher [channels options](https://pusher.com/docs/channels/using_channels/connection/#channels-options-parameter) parameter:

| Options             | Type         | description        |
|---------------------|--------------|--------------------|
| cluster             | string       | The [cluster](https://pusher.com/docs/channels/miscellaneous/clusters/) used by your application |
| userAuthentication  | dictionary   | See [below](#userauthentication) |
| channelAuthorization  | dictionary   | See [below](#channelauthorization) |

### UserAuthentication:

Based on Pusher [userAuthentication](https://pusher.com/docs/channels/using_channels/connection/#userauthentication-849556825) object:
| Option             | Type         | description        |
|---------------------|--------------|--------------------|
| params              | dictionary   | Additional parameters |
| headers             | dictionary   | Additional HTTP headers |
| endpoint            | string       | URL [endpoint](https://pusher.com/docs/channels/using_channels/connection/#userauthenticationendpoint-1618076675) of server for authentication. |

### ChannelAuthorization:

Based on Pusher [channelAuthorization](https://pusher.com/docs/channels/using_channels/connection/#channelauthorization-1528180693) object:
| Option             | Type         | description        |
|---------------------|--------------|--------------------|
| params              | dictionary   | Additional parameters |
| headers             | dictionary   | Additional HTTP headers |
| endpoint            | string       | URL [endpoint](https://pusher.com/docs/channels/using_channels/connection/#channelauthorizationendpoint-1363574431) |

### Loggin
By default we don’t log anything. If you want to debug your application and see what’s going on within Channels then you can assign a global logging function.
The `_log` value should be set with a function with the following signature:

```swift
$Pusher._log = funcref(self, "logger")
  
func logger(message):
	print(message)
```

## Connection
A connection to Pusher Channels can be established by invoking the `connect_app` method of your pusher node:
```swift
$Pusher.connect_app()
```
A connection with custom configuration can be established by passing the same params from [configure](#runtime) method:
```swift
$Pusher.connect_app(APP_KEY, { "cluster": APP_CLUSTER })
```
### Disconnect
You may disconnect by invoking the `disconnect_app` method:
```swift
$Pusher.disconnect_app()
```
## Channels

### Subscribing to channels
The default method for subscribing to a channel involves invoking the `subscribe` method of your pusher node:
```swift
$Pusher.subscribe("my-channel");
```

### Unsubscribing from channels
To unsubscribe from a channel, invoke the `unsubscribe` method of your pusher object:
```swift
$Pusher.unsubscribe("my-channel");
```

### Accessing channels
If a channel has been subscribed to already it is possible to access channels by name, through the `channel` method:
```swift
var channel = $Pusher.channel("channel-name")
```




## Binding to events

### Binding on the client:
Use the `bind` method of the pusher node to listen for an event on all the channels that you are currently subscribed to:

```swift
$Pusher.bind(EVENT, CALLBACK);
```
Params of the `bind` method:

| Param            | Type         | description             |
|------------------|--------------|-------------------------|
| event            | string       | The name of the event to bind to. | 
| callback         | funcRef      | Called whenever the event is triggered. See [below](#event-callback) |

### Event callback
In GDScript, functions are not first-class objects. This means it is impossible to store them directly as variables, return them from another function, or pass them as arguments.

However, by creating a FuncRef reference to a function in a given object can be created, passed around and called:

```swift
func event_handler(data):
  print("Event received")
  
var callback = funcref(self, "event_handler")
```

### Binding on the channel
Events can be bound to directly on a channel. This means you will only receive an event if it is sent on that specific channel:
```swift
channel.bind(eventName, callback);
```

### Unbinding from events:
Use `unbind` to remove a binding of an event:

```swift
$Pusher.unbind(EVENT, CALLBACK);
```

Params of the `unbind` method:

| Param            | Type         | description             |
|------------------|--------------|-------------------------|
| event            | string       | The name of the event from which your want to remove the binding. | 
| callback         | funcRef      | The function reference used when binding to the event.    |

