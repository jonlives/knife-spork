Campfire
========
Automatically posts informational messages to Campfire

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'campy'
```

Hooks
-----
- `after_promote`
- `after_upload`

Configuration
-------------
```yaml
plugins:
  campfire:
    account: my_company
    token: ABC123
    rooms:
      - General
      - Web Operations
```

#### account
This is your campfire account name. It is the subdomain part of your account.

- Type: `String`

#### token
This is the secure token you get from the Campfire configuration.

- Type: `String`

#### Rooms
This is an array of room names to post messages to.

- Type: `String`
