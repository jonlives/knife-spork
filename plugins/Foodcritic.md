Foodcritic
==========
Automatically runs foodcritic against your cookbooks on check and upload.

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'foodcritic' >= 3.0.0
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
    tags:
      - FC0023
    fail_tags:
      - any
    include_rules:
      - foodcritic/etsy
    epic_fail: true
```

#### tags
The tags to check against.

- Type: `Array`
- Default: '[any]'

#### fail_tags
The list of tags to fail on.

- Type: 'Array'
- Default: '[any]'

#### include_rules
An optional list of additional rules to run.

- Type: `Array`

#### epic_fail:
If set to true, `epic_fail` will prevent you from uploading a cookbook until all foodcritic rules pass.

- Type: `Boolean`
- Default: `true`
