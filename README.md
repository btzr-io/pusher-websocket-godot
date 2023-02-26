# Pusher Channels ( client addon )

A [Pusher Channels](https://pusher.com/channels) client  addon for [Godot](https://github.com/godotengine/godot).

Create real-time interactions with the [Pusher Channels Protocol](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/) over a [WebSocket connection](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html).

## Installation
Move the [./addons](https://github.com/btzr-io/pusher-websocket-godot/tree/main/addons/) folder into your project folder. See guide: [Installing a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)

## Usage

1) Enable the plugin. See guide: [Enabling a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#enabling-a-plugin)
2) Add a `Pusher` node to your main scene.

## Configuration

### Editor inspector
Minimal configuration is available in the inspector but is recommended to use the [configure](#runtime) method:

![image](https://user-images.githubusercontent.com/14793624/221388478-c83e698a-1326-4d03-b98f-00390e9b8624.png)

### Runtime

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

Based on Pusher [channels options](https://pusher.com/docs/channels/using_channels/connection/#channels-options-parameter)

| Options             | Type         | description        |
|---------------------|--------------|--------------------|
| cluster             | string       | The [cluster](https://pusher.com/docs/channels/miscellaneous/clusters/) used by your application |
| userAuthentication  | dictionary   | See [below](#userauthentication) |

### UserAuthentication:

Based on Pusher [userAuthentication](https://pusher.com/docs/channels/using_channels/connection/#userauthentication-849556825) object:
| Options             | Type         | description        |
|---------------------|--------------|--------------------|
| params              | dictionary   | Additional [parameters](https://pusher.com/docs/channels/using_channels/connection/#userauthenticationparams-133540021) |
| headers             | dictionary   | Additional HTTP [headers](https://pusher.com/docs/channels/using_channels/connection/#userauthenticationheaders-168766504) |
| endpoint            | string       | URL [endpoint](https://pusher.com/docs/channels/using_channels/connection/#userauthenticationendpoint-1618076675) of server for authentication. |

## Connection
A connection to Pusher Channels can be established by invoking the `connect_app` method of your pusher node:
```swift
$Pusher.connect_app()
```
A connection with custom configuration can be established by passing the same params from `configure` method:
```swift
$Pusher.connect_app(APP_KEY, { "cluster": APP_CLUSTER })
```

You may disconnect again by invoking the `disconnect_app` method:
```swift
$Pusher.disconnect_app()
```

## Subscribing to channels
The default method for subscribing to a channel involves invoking the `subscribe` method of your pusher node:
```swift
$Pusher.subscribe("my-channel");
```

## Unsubscribing from channels
To unsubscribe from a channel, invoke the `unsubscribe` method of your pusher object:
```swift
$Pusher.unsubscribe("my-channel");
```


## Signals
Pusher node signals:

| Signal        | Params                               | description        |
|---------------|--------------------------------------|--------------------|
| error         | { code: int, message: str }          | Emitted for the [pusher:error](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#pushererror-pusher-channels-greater-client) event    |
| connected     | { socket_id: str, timeout: int }     | Emitted for the [pusher:connection_established]( https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#pusherconnection_established-pusher-channels-greater-client) event |
| state_changed | state: str                           | Emitted for all [connection state](https://pusher.com/docs/channels/using_channels/connection/#connection-states) changes         |
