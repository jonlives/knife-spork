Eventinator
===========

Gem Requirements
----------------
This plugin has no gem requirements.

Hooks
-----
- `after_upload`

Configuration
-------------
```yaml
plugins:
  eventinator:
    url: www.example.com
    read_timeout: 5
```

#### url
The server to post to.

- Type: `String`

#### read_timeout
The timeout, in seconds, for the request to return.

- Type: `Integer`
- Default: `5`
