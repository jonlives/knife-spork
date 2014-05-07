Rubocop
==========
Automatically runs rubocop against your cookbooks on check and upload.
This is entirely based off of the Foodcritic plugin.

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
  rubocop:
    epic_fail: true
    show_name: false
    autocorrect: false
    out_file: <file>
    sev_level: <C|W|E>
    lint: false
```

#### epic_fail:
If set to true, `epic_fail` will prevent you from uploading a cookbook or further checks from running until rubocop passes.
- Type: `Boolean`
- Default: `true`

#### The following options are passing command line options to rubocop.  See rubocop --help for more details
#### show_name:
- Type: `Boolean`
- Default: `false`
- Rubocop command line equivilant: "-D"
Shows the name of the offending rule as well as the decription and line reference.

#### autocorrect:
- Type: `Boolean`
- Default: `false`
- Rubocop command line equivilant: "--auto-correct"
Automatically correct some offenses.

#### out_file:
- Type: `String` - file name
- Default: nil
- Rubocop command line equivilant: "--out <file>"
Redirects the rubocop output to a file instead of STDOUT.

#### sev_level:
- Type: `String`
- Default: nil
- Rubocop command line equivilant: "--fail-level [C|W|E]"
Set the severity level at which Rubocop will fail (see rubocop --help for more).

#### lint:
- Type: `Boolean`
- Default: `false`
- Rubocop command line equivilant: "--lint"
Only run linting rules.
