Campfire
========
Automatically posts informational messages to Grove.io

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'rest_client'
```

Hooks
-----
- `after_promote`
- `after_upload`

Configuration
-------------
```yaml
plugins:
  grove:
    tokens:
      - ABC
      - XYZ
```

#### Tokens
This is an array of tokens (channels) to post messages to.

- Type: `String`
