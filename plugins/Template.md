Plugin Name
===========
Here is an optional, short description about your plugin.

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'my_gem', '~> 1.4.5'
gem 'other_gem', '>= 5.0.1'
```

Hooks
-----
- `after_promote`

Configuration
-------------
```yaml
plugins:
  plugin_name:
    option_1: true
    option_2:
      - a
      - b
      - c
```

#### option_1
This is a description of the option.

- Type: `String`
- Default: `ABC`
