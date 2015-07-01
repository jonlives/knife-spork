Git
===
This plugin attempts to help manage your workflow by automatically pulling changes from your repo. **Do not use this plugin if you are not using Git.**

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
    auto_push: true
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
The git branch to push/pull to/from.

- Type: `String`
- Default: `master`

#### auto_push
An optional true / false parameter indicating whether or not subcommands manipulating environment, role, node, databag files should be automatically comitted and pushed to Git

- Type: `Boolean`
- Default: `false`
