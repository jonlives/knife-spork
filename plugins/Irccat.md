Plugin Name
===========
Here is an optional, short description about your plugin.

Gem Requirements
----------------
This plugin has no gem requirements.`

Hooks
-----
- `after_promote`

Configuration
-------------
```yaml
plugins:
  irccat:
    server: irc.example.com
    port: 54
    channels:
      - #chef
      - #knife
```

#### server
The url of the IRC server.

- Type: `String`

#### port
The port of the IRC server.

- Type: `String`

#### channels
The channels to post to.

- Type: `Array`
