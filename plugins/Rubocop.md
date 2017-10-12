Rubocop
==========
Automatically runs rubocop (or [cookstyle](https://github.com/chef/cookstyle) - its chef-focused brother) against your cookbooks on check and upload.
This is entirely based off of the Foodcritic plugin.

Gem Requirements
----------------
This plugin requires the following gems:

```ruby
gem 'rubocop'
gem 'cookstyle' # if you wish to use cookstyle behaviour
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
    use_cookstyle: true
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

#### use_cookstyle:
- Type: `Boolean`
- Default: `false`
- Rubocop command line equivilant: none, use `cookstyle` command instead of `rubocop` command
Cookstyle is a set of rubocop configurations that are specific to cookbooks.

#### Example
``` ruby
chef_workstation01$ knife spork check chef-client
Checking versions for cookbook chef-client...

Local Version:
  3.3.3

Remote Versions: (* indicates frozen)
  3.3.3
  3.2.0

ERROR: The version 3.3.3 exists on the server and is not frozen. Uploading will overwrite!
Running rubocop against chef-client@3.3.3...
/home/chef-repo/cookbooks/chef-client
Inspecting 25 files
....CCCCC.CWCCCCCWCCCWCCC

Offenses:

chef-client/files/default/tests/minitest/config_test.rb:22:53: C: Prefer single-quoted strings when you don't need string interpolation or special symbols.
    file(File.join(node['chef_client']['conf_dir'], "client.rb")).must_exist
                                                    ^^^^^^^^^^^
chef-client/libraries/helpers.rb:35:72: C: Prefer single-quoted strings when you don't need string interpolation or special symbols.
          Chef::Log.debug("Node has Chef Server Recipe? #{node.recipe?("chef-server")}")
                                                                       ^^^^^^^^^^^^^
chef-client/libraries/helpers.rb:36:70: C: Prefer single-quoted strings when you don't need string interpolation or special symbols.
          Chef::Log.debug("Node has Chef Server Executable? #{system("which chef-server > /dev/null 2>&1")}")
                                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
chef-client/libraries/helpers.rb:37:74: C: Prefer single-quoted strings when you don't need string interpolation or special symbols.
          Chef::Log.debug("Node has Chef Server Ctl Executable? #{system("which chef-server-ctl > /dev/null 2>&1")}")
                                                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
...

```
