StatusNet
=======
StatusNet posts messages to a your StatusNet instance

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'curb'
```

Hooks
-----
- `after_upload`
- `after_promote`

Configuration
-------------
```yaml
plugins:
  statusnet:
    url: YOUR INSTANCE API URL
    username: YOURUSER
    password: YOURPASSWORD
```

#### url
Your StatusNet instance API url, usually server url + /api/statuses/update.xml

- Type: `Srtring`

#### username
Your StatusNet username.

- Type: `String`

#### password
Your StatusNet password.

- Type: `String`
