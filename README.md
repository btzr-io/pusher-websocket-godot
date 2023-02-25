# Pusher Channels ( client addon )

A [Pusher Channels](https://pusher.com/channels) client  addon for [Godot](https://github.com/godotengine/godot).

Create realtime interactions with the [Pusher Channels Protocol](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/) over a [WebSocket connection](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html).

## Installation
Move the [./addons](https://github.com/btzr-io/pusher-websocket-godot/tree/main/addons/) folder into your project folder. See guide: [Installing a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)

## Usage

1) Enable the plugin. See guide: [Enabling a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#enabling-a-plugin)

2) Add a `Pusher` node to your main scene.

3) Configure the `Pusher` node, don't forget to set your [app key](https://pusher.com/docs/channels/using_channels/connection/#applicationkey-2105278448) and [cluster name](https://pusher.com/docs/channels/miscellaneous/clusters/).

## Connection
A connection to Pusher Channels can be established by invoking the `connect_app` method of your pusher node:
```swift
$Pusher.connect_app()
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

## Properties
Pusher node configurtion properties:

| Property       | Type     | description        |
|----------------|----------|--------------------|
| key            | string   |                    |
| cluster        | string   |                    |
| auth_endpoint  | string   |                    |
| auto_connect   | boolean  |                    |
| auto_signin    | boolean  |                    |



## Methods
Pusher node methods:

| Method          | params   | description        |
|-----------------|----------|--------------------|
| connect_app     |          |                    |
| disconnect_app  |          |                    |
| signin          |          |                    |
| subscribe       |          |                    |
| unsuscribe      |          |                    |
| trigger         |          |                    |
| trigger_channel |          |                    |

## Signals
Pusher node signals:

| Signal        | Params                               | description        |
|---------------|--------------------------------------|--------------------|
| error         | { code: int, message: str }          | Emited for the [pusher:error](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#pushererror-pusher-channels-greater-client) event    |
| connected     | { socket_id: str, timeout: int }     | Emited for the [pusher:connection_established]( https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#pusherconnection_established-pusher-channels-greater-client) event |
| state_changed | state: str                           | Emited for all [connection state](https://pusher.com/docs/channels/using_channels/connection/#connection-states) changes         |
