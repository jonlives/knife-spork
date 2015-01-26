Influxdb
========

Annouce influxdb about your chef deployments

Gem Requirements
----------------
`gem influxdb`

Hooks
-----
- `after_upload`

Configuration
-------------
```yaml
plugins:
  influxdb:
    database: deployments
    username: deploy
    password: deploy
    series: deployments
    host: influx.example.com
    port: 8086
```
