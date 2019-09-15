Changelog
=========
This plugin attempts to help manage your workflow by automatically adding a templated entry to the CHANGELOG.md file when performing a bump action.

Gem Requirements
----------------
This plugin has no gem requirements.

Hooks
-----
- `after_bump`

Configuration
-------------
```yaml
plugins:
  changelog:
    preserve_lines: 5
    default_comment: "Version bump, no functional changes"
```

**Note** You may choose to accept all the defaults. In that case, you should make your configuration like this:

```yaml
plugins:
  changelog:
    enabled: true
```

#### preserve_lines
A number of lines to be preserved at the head of the CHANGELOG.md file. Use if your standard CHANGELOG.md format includes a header section which you would like to remain at the top of the file.

- Type: `Integer`
- Default: `0`

#### default_comment
The comment added to the CHANGELOG.md file along with the author's username and the new version number.

- Type: `String`
- Default: `Bump`
