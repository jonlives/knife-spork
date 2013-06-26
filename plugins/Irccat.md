Plugin Name
===========
This plugin interfaces with the irccat IRC bot (https://github.com/RJ/irccat)

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
    gist: "/usr/bin/gist"
    template:
          upload: "foo bar! #REDCHEF:#NORMAL %{organization}%{current_user} uploaded #GREEN%{cookbooks}#NORMAL"
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

#### gist
Optional path to gist binary installed by https://rubygems.org/gems/gist

- Type: `String`


### template
Optional irccat message template if you want to change the formatting of irccat alerts. Supports overriding alerts for upload and promote