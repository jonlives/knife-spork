Git
===
This plugin attempts to manage your workflow by automatically pulling, committing, and pushing your changes to the remote repository. **Do not use this plugin if you are not using Git.**

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'git'
```

Hooks
-----
- `before_bump`
- `after_bump`
- `after_promote`

Configuration
-------------
```yaml
plugins:
  git:
    remote: origin
    branch: master
```

**Note** Due to the nature of the git plugin, it's possible that you accept all the defaults. In that case, you should make your configuration like this:

```yaml
plugins:
  git:
    enabled: true
```

#### remote
The git remote to push/pull to/from.

- Type: `String`
- Default: `origin`

#### branch
The git brnach to push/pull to/from.

- Type: `String`
- Default: `master`
