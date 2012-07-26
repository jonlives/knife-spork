Graphite
========
Graphite will automatically send a request to your Graphite server under the deploys.chef.[environment] for graphical analysis.

Gem Requirements
----------------
This plugin has no gem requirements.

Hooks
-----
- `after_promote`

Configuration
-------------
```yaml
plugins:
  graphite:
    server: graphite.example.com
    port: 12345
```

#### server
The url to the graphite server

- Type: `String`

#### port
The port of the graphite server

- Type: `Integer`
