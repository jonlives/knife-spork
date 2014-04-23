Rubocop
==========
Automatically runs rubocop against your cookbooks on check and upload.
This is based entirely off of the Foodcritic plug-in

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'rubocop'
```

Hooks
-----
- `after_check`
- `before_upload`

Configuration
-------------
```yaml
plugins:
  foodcritic:
    epic_fail: true
```

#### epic_fail:
If set to true, `epic_fail` will prevent you from uploading a cookbook until all foodcritic rules pass.

- Type: `Boolean`
- Default: `true`

#### TO-DO
Would like to include options to set severity-level and possibly specifiying output file.
