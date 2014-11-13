HipChat
=======
HipChat posts messages to your HipChat client.

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'hipchat'
```

Hooks
-----
- `after_upload`
- `after_promote`

Configuration
-------------
```yaml
plugins:
  hipchat:
    server_url: https://api.hipchat.com
    api_token: ABC123
    api_version: v1
    rooms:
      - General
      - Web Operations
    notify: true
    color: yellow
    gist: /usr/bin/gist
```

#### server_url
The URL of the HipChat API server. Default: 'https://api.hipchat.com'

- Type: `String`

#### api_token
Your HipChat API token.

- Type: `String`

#### api_version
Which version of the HipChat API to use. Default: 'v1'

- Type: `String`

#### rooms
The list of rooms to post to.

- Type: `Array`

#### notify
Boolean value indicating whether the room should be notified.

- Type: `Boolean`

#### color
The color of the message.

- Type: `String`
- Acceptable Values: `[yellow, red, green, purple, random]`

#### gist
Optional path to gist binary installed by https://rubygems.org/gems/gist

- Type: `String`

