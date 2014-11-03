Slack
=======
Slack posts messages to your Slack client.

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'slack-notifier'
```

Hooks
-----
- `after_upload`
- `after_promote`

Configuration
-------------
```yaml
plugins:
  slack:
    api_token: ABC123
    channel: "#operations"
    teamname: myteam
    username: knife
```

#### api_token
Your Slack API token.

- Type: `String`

#### channel
The channel to post to.

- Type: `String`

#### teamname
The teamname of the slack account. ex. https://TEAMNAME.slack.com

- Type: `String`

#### username
The username to post as.

- Type: `String`

#### icon_url
The url for icon. ex. https://example.com/image.jpg, default: nil

- Type: `String`
