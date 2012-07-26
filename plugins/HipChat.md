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
    api_token: ABC123
    rooms:
      - General
      - Web Operations
    notify: true
    color: yellow
```

#### api_token
Your HipChat API token.

- Type: `String`

#### rooms
The list of rooms to post to.

- Type: `Array`

#### notify
Boolean value indicating whether the room should be notified.

- Type: `Boolean`

#### color
THe color of the message.

- Type: `String`
- Acceptable Values: `[yellow, red, green, purple, random]`
