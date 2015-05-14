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
    bump_tag: false
    bump_commit: false
    bump_comment: false
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
An optional true / false parameter indicating whether or not changes should be automatically comitted and pushed to Git

- Type: `Boolean`
- Default: `false`

#### bump_tag
A git tag will be created after a cookbook bump in the format
<cookbook name>-<new version string>

- Type: `Bouleen`
- Default: `false`

#### bump_comment
This option is intended to take the comment entered when using the general :bump_comment option.
This option is meaningless without also enabling bump_commit.
The comment entered into the CHANGE_LOG.md will be used as the git commit message in the following format.
	'[KnifeSpork] <user> - <comment>'

- Type: `Bouleen`
- Default: `false`

#### bump_commit
All changes will be commited locally after a cookbook bump.
If the bump_comment option is used (above) the commit meessage described there will be used.  Otherwise,
the commit message will be:
	'[KnifeSpork] Bumping <cookbook name> to <new version string>'

- Type: `Bouleen`
- Default: `false`

