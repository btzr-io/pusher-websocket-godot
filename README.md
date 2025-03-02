# :rocket: Pusher Channels ( godot plugin )

A [Godot](https://github.com/godotengine/godot) plugin for creating real-time interactions with the [Pusher Channels Protocol](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/) over a [WebSocket connection](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html).


| Plugin version   | Godot version  | Pusher Channels Protocol version |
|------------------|----------------|----------------------------------|
| 1.0              | 3.5.1          | 7.0                              |
| 2.0              | 4.3            | 7.0                              |


## Table of Contents
- [Installation](#installation)
- [Quick start](#quick-start)
  - [Activation](#activation)
  - [Open a connection](#open-a-connection)
  - [Listen for connection events](#listen-for-connection-events)
  - [User authentication](#user-authentication)
  - [Subscribe to a channel](#subscribe-to-a-channel)
  - [Listen for events on your channel](#listen-for-events-on-your-channel)
  - [Triggering client events](#triggering-client-events)
  
- [Configuration](#configuration)
    - [Options](#options)
       - [UserAuthentication](#userauthentication)
       - [ChannelAuthorization](#userauthentication)
    - [Loggin](#loggin)
- [Connection](#configuration)
  - [Disconnect](#disconnect)
  - [connection-states](#connection-states)
    - [Available states](#available-states)
- [Channels](#channels)
  - [Subscribing to channels](#subscribing-to-channels)
  - [Unsubscribing from channels](#unsubscribing-from-channels)
  - [Accessing channels](#accessing-channels)
- [Binding to events](#binding-to-events)
  - [Event callback](#event-callback)
  - [Binding on the client](#binding-on-the-client)
  - [Binding on the channel](#binding-on-the-channel)
  - [Unbinding from events](#unbinding-from-events)
  
## Installation
Move the [./addons](https://github.com/btzr-io/pusher-websocket-godot/tree/main/addons/) folder into your project folder.

See full guide: [Installing a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)


## Quick start
### Activation
Enable the plugin, see full guide: [Enabling a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#enabling-a-plugin)

### Get your Free API keys
Create an [account](https://dashboard.pusher.com/accounts/sign_up) and then create a Channels app. 
See full [guide](https://pusher.com/docs/channels/getting_started/javascript/?ref=sdk-quick-starts#get-your-free-api-keys)


### Open a connection
```swift
Pusher.connect_app( APP_KEY, { "cluster": APP_CLUSTER } )
```

### Listen for connection events:
```swift
func connected_handler(data):
  print("Hello!")
  
 func error_handler(data):
  print("Oh No!")

Pusher.connection_established.connect(connected_handler);
Pusher.connection_error.connect(error_callback);
```

### User authentication

Authentication happens when you call the signin `method`:

```js
Pusher.signin()
```

See full [documentation](https://pusher.com/docs/channels/using_channels/user-authentication/)

### Subscribe to a channel

Before your app can receive any events from a channel, you need to subscribe to the channel. Do this with the `subscribe` method:
```swift
var channel = Pusher.subscribe("channel-name")
```

### Listen for events on your channel
Every published event has an “event name”. For your app to do something when it receives an event called "my-event", your web app must first “bind” a function to this event name. Do this using the channel’s `bind` method:

```swift 
func event_handler(event_data):
  print(event_data)

channel.bind("my-event", event_handler)
```

### Triggering client events
You can only trigger a client event once a subscription has been successfully registered:
```swift

var channel = Pusher.subscribe("channel-name")
channel.bind(PusherEvent.SUBSCRIPTION_SUCCEEDED, handle_subscription);

func handle_subscription():
	channel.trigger("client-someEventName", { "message": "hello!" })
```
See full [documentation](https://pusher.com/docs/channels/using_channels/events/#triggering-client-events)



## Configuration

It is possible to set and update the client configuration through the `configure` method:

```swift
Pusher.configure(KEY, OPTIONS)
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
By default nothing will be log to the debug console. If you want to debug your application and see what’s going on within Channels then you can set the `debug` value to true:

```swift
Pusher.debug = true
```

## Connection
A connection to Pusher Channels can be established by invoking the `connect_app` method, the configuration can be established by passing the same params from [configure](#runtime) method:

```swift
$Pusher.connect_app(APP_KEY, { "cluster": APP_CLUSTER })
```

### Disconnect
You may disconnect by invoking the `disconnect_app` method:

```swift
Pusher.disconnect_app()
```

### Connection States
You can monitor the state of the connection so that you can notify users about expected behaviour.
 See guide: [connection states API](https://pusher.com/docs/channels/using_channels/connection/#connection-states)

####  Available states
You can access the current state as:

```swift
Pusher.connection_state
```

 To listen for connection state changes use the connection_state_changed signal: 
 
 ```swift
$Pusher.connection_state_changed.connect(callback)
 ```

All state names are available as constants trough the `PusherState` class:

```swift
// PusherState.CONNECTED == "connected"
```

See full list: [Available connection states](https://pusher.com/docs/channels/using_channels/connection/#available-states)

## Channels

### Subscribing to channels
The default method for subscribing to a channel involves invoking the `subscribe` method:
```swift
Pusher.subscribe("my-channel");
```

### Unsubscribing from channels
To unsubscribe from a channel, invoke the `unsubscribe` method:
```swift
$Pusher.unsubscribe("my-channel");
```

### Accessing channels
If a channel has been subscribed to already it is possible to access channels by name, through the `get_channel` method:
```swift
var channel = Pusher.get_channel("channel-name")
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
| callback         | Callable     | Called whenever the event is triggered. |

### Binding on the channel
Events can be bound to directly on a channel. This means you will only receive an event if it is sent on that specific channel:
```swift
channel.bind(eventName, callback)
```

### Unbinding from events:
Use `unbind` to remove a binding of an event:

```swift
Pusher.unbind(EVENT, CALLBACK)
```

Params of the `unbind` method:

| Param            | Type         | description             |
|------------------|--------------|-------------------------|
| event            | string       | The name of the event from which your want to remove the binding. | 
| callback         | Callable     | Callable used when binding to the event.    |

