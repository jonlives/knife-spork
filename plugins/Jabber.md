Jabber
=======
Jabber posts messages to a designated Jabber group chat room.

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'xmpp4r'
```

Hooks
-----
- `after_upload`
- `after_promote`

Configuration
-------------
```yaml
plugins:
  jabber:
    username: YOURUSER
    password: YOURPASSWORD
    nickname: Chef Bot
    server_name: your.jabberserver.com
    server_port: 5222
    rooms:
      - engineering@your.conference.com/spork
      - systems@your.conference.com/spork
```

#### username
Your Jabber username.

- Type: `String`

#### password
Your Jabber password.

- Type: `String`

#### nickname
A nickname to use in the conference room when making announcements.

- Type: `String`

#### server_name
Your Jabber server name.

- Type: `String`

#### server_port
Your Jabber server port number. Default: 5222

- Type: `String`

#### rooms
The list of rooms to post to.

- Type: `Array`
