KnifeSpork
===========
KnifeSpork is a workflow plugin for `Chef::Knife` which helps multiple developers work on the same Chef Server and repository without treading on each other's toes. This plugin was designed around the workflow we have here at Etsy, where several people are working on the Chef repository and Chef Server simultaneously. It contains several functions, documented below:

[![Build Status](https://travis-ci.org/jonlives/knife-spork.svg)](https://travis-ci.org/jonlives/knife-spork)
[![Gem Version](https://badge.fury.io/rb/knife-spork.png)](http://badge.fury.io/rb/knife-spork)

Installation
------------

### Gem Install
`knife-spork` is available on rubygems. Add the following to your `Gemfile`:

```ruby
gem 'knife-spork'
```

or install the gem manually:

```bash
gem install knife-spork
```

knife-spork is also included in the [Chef Devlopment Kit](https://downloads.chef.io/chef-dk/).

**Please note**: As of version 1.6.0, knife-spork requires Ruby 2.1.1 or greater and Chef version 11.0.0 or greater. If you're still using < Ruby 2.0 or Chef 11, please continue to use knife-spork 1.5.x
Spork Configuration
-------------------
Out of the box, knife spork will work with no configuration. However, you can optionally enable several features to enhance its functionality.

KnifeSpork will look for a configuration file in the following locations, in ascending order of precedence:

- `config/spork-config.yml`
- `/etc/spork-config.yml`
- `~/.chef/spork-config.yml`
- `.chef/spork-config.yml`

Anything set in the configuration file in your home directory for example, will override options set in your Chef repository or `/etc`.

Below is a sample config file with all supported options and all shipped plugins enabled below, followed by an explanation of each section.

```yaml
default_environments:
  - development
  - production
environment_groups:
  qa_group:
    - quality_assurance
    - staging
  test_group:
    - user_testing
    - acceptance_testing
version_change_threshold: 2
preserve_constraint_operators: true
environment_path: "/home/me/environments"
save_environment_locally_on_create: false
role_path: "/home/me/roles"
custom_plugin_path: "/home/me/spork-plugins"
always_promote_remote: true
skip_berkshelf: false
role_match_file_name: true
role_safe_delete: true
stdout_diffs
json_options:
  indent: "    "
plugins:
  campfire:
    account: myaccount
    token: a1b2c3d4...
  foodcritic:
    tags: ['any']
  hipchat:
    api_token: ABC123
    rooms:
      - General
      - Web Operations
    notify: true
    color: yellow
  jabber:
    username: YOURUSER
    password: YOURPASSWORD
    nickname: Chef Bot
    server_name: your.jabberserver.com
    server_port: 5222
    rooms:
      - engineering@your.conference.com/spork
      - systems@your.conference.com/spork
  git:
    enabled: true
    auto_push: true
    branch: some_branch
  irccat:
    server: irccat.mydomain.com
    port: 12345
    gist: "/usr/bin/gist"
    channel: ["chef-annoucements"]
  graphite:
    server: graphite.mydomain.com
    port: 2003
  influxdb:
    database: deployments
    username: deploy
    password: deploy
    series: deployments
    host: influx.example.com
    port: 8086
  eventinator:
    url: http://eventinator.mydomain.com/events/oneshot
  slack:
    webhook_url: https://hooks.slack.com/services/ABCD/efgh
    channel: "#sysops"
    username: knife
    icon_url: http://example.com/image.jpg
  rubocop:
    epic_fail: true
    show_name: false
    autocorrect: false
    out_file: <file>
    sev_level: <C|W|E>
    lint: false
    use_cookstyle: true
```

#### Default Environments
The `default_environments` directive allows you to specify a default list of environments you want to promote changes to. If this option is configured and you *omit* the environment parameter when promoting KnifeSpork will promote to all environments in this list.

#### Environment Groups
The `environment_groups` directive allows you to specify a list of environments referenced by group names that you want to promote changes to.

#### Version Change Threshold
The `version_change_threshold` directive allows you to customise the threshold used by a safety check in spork promote which will prompt for confirmation if you're promoting a cookbook by more than version_change_threshold versions. This defaults to 2 if not set, ie promoting a cookbook from v1.0.1 to v 1.0.2 will not trip this check, wheras promoting from v1.0.1 to v1.0.3 will.

#### Preserve Constraint Operators
The `preserve_constraint_operators` directive causes spork promote to preserve existing version constraint operators in your environment files, only updating the version number. This directive is disabled by default, which causes spork to always use the `=` constraint.

#### Always Promote Remote
The `always_promote_remote` directive allows you to tell spork promote to always act as if the --remote option had been specified. This will also have the same effect on spork omni. This option should only be used if you're sure you want all changes to be uploaded to the server as soon as you run promote.

#### Skip Berkshelf
The `skip_berkshelf` directive is a temporary flag added in [#138](https://github.com/jonlives/knife-spork/issues/138) to allow Berkshelf functionality to be optionally bypassed until Berkshelf 3 support has been added to knife-spork per [#85](https://github.com/jonlives/knife-spork/issues/85). It simply removed the :Berkshelf constant from the namespace used by knife-spork.

#### JSON Options
The `json_options` directive allows you to tell spork to pass options to [pretty_generate](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/json/rdoc/JSON.html#method-i-pretty_generate) to control the format of the resulting json

#### Environment Path
The `environment_path` directive allows you to specify the path to where you store your chef environment json files. If this parameter is not specified, spork will default to using the first element of your cookbook_path, replacing the word "cookbooks" with "environments"

#### Save Environment on Create
The `save_environment_on_create` directive allows you to have the ```knife spork environment create``` command save a copy of the new environment to your Chef repository. This will default to saving environment files in the location specified by the ```environment_path``` directive. If this parameter is not specified, spork will default to using the first element of your cookbook_path, replacing the word "cookbooks" with "environments"


#### Role Path
The `role_path` allows you to specify the path to where you store your chef role json files. If this parameter is not specified, spork will default to using the first element of your cookbook_path, replacing the word "cookbooks" with "roles"

#### Role Safe Delete
The `role_safe_delete` flag will, when you use the spork ```knife spork role delete``` command, check to see if any nodes currently have that role in their runlist and exit with an error message if any are found.

#### Role Match File Name
The `role_match_file_name` flag allows you to check whether the file name that is used to upload a role matches the role name as well. If the parameter is specified, or flag `--match-filename` is set, spork will not let you upload a role from a file unless the name matches the rolename.

#### Stdout Diffs
The `stdout_diffs` flag will cause any diffs generated by knife-spork (for example on events such as data bag uploads, role edits etc) to be displayed on stdout in addition to any notifications generated by plugins.


#### Custom Plugin Path
The `custom_plugin_path` allows you to specify an additional directory from which to load knife-spork plugins. If this parameter is not specified or the path set does not exist, only the default plugins shipped with knife-spork will be loaded (if enabled in config)


#### Plugins
Knife spork supports plugins to allow users to hook it into existing systems such as source control, monitoring and chat systems. Plugins are enabled / disabled by adding / removing their config block from the plugin section of the config file. Any of the default plugins shown above can be disabled by removing their section.

For more information on how to develop plugins for spork, please read the [plugins/README.md](plugins/README.md) file.

Spork Info
-----------
This function is designed to help you see which plugins you currently have loaded, and the current config Hash which knife spork is using.

#### Usage
```bash
knife spork info
```

#### Example

```text
$ knife spork info
Config Hash:
{"plugins"=>{"git"=>{"enabled"=>true}, "irccat"=>{"server"=>"irccat.mydomain.com", "port"=>12345, "gist"=>"usr/bin/gist", "channel"=>["#chef-announce"]}, "graphite"=>{"server"=>"graphite.mydomain.com", "port"=>2003}, "slack"=>{"api_token"=>"abc123", "channel"=>"random", "teamname"=>"myteam", "icon_url"=>"http://example.com/image.jpg"}, "eventinator"=>{"url"=>"http://eventinator.mydomain.com/events/oneshot"}}, "default_environments"=>["development", "production"], "version_change_threshold"=>2, "pplugins"=>{"foodcritic"=>{"fail_tags"=>["style,correctness,test"], "tags"=>["~portability"], "include_rules"=>["config/rules.rb"]}}}

Plugins:
KnifeSpork::Plugins::Campfire: disabled
KnifeSpork::Plugins::Eventinator: enabled
KnifeSpork::Plugins::Foodcritic: disabled
KnifeSpork::Plugins::Git: enabled
KnifeSpork::Plugins::Graphite: enabled
KnifeSpork::Plugins::HipChat: disabled
KnifeSpork::Plugins::Slack: enabled
KnifeSpork::Plugins::Irccat: enabled
```

Spork Check
-----------
This function is designed to help you avoid trampling on other people's cookbook versions, and to make sure that when you come to version your own work it's easy to see what version numbers have already been used and if the one you're using will overwrite anything.

#### Usage
```bash
knife spork check COOKBOOK [--all]
```

By default, spork check only shows the 5 most recent remote cookbook versions. Add the --all option if you want to see everything.

#### Example (Checking an Unfrozen Cookbook with version clash)

```text
$ knife spork check apache2
Checking versions for cookbook apache2...

Local Version:
  1.1.49

Remote Versions: (* indicates frozen)
 *2.0.2
 *2.0.1
  1.1.49
 *1.1.14
 *1.1.13

ERROR: The version 1.1.49 exists on the server and is not frozen. Uploading will overwrite!
```

#### Example (Checking a Frozen Cookbook with version clash)

```text
$ knife spork check apache2
Checking versions for cookbook apache2...

Local Version:
  2.0.2

Remote Versions: (* indicates frozen)
 *2.0.2
 *2.0.1
  1.1.49
 *1.1.14
 *1.1.13

WARNING: Your local version (2.0.2) is frozen on the remote server. You'll need to bump before you can upload.
````

#### Example (No version clashes)

```text
$ knife spork check apache2
Checking versions for cookbook apache2...

Local Version:
  2.0.3

Remote Versions: (* indicates frozen)
 *2.0.2
 *2.0.1
  1.1.49
 *1.1.14
 *1.1.13

Everything looks good!
```

Spork Bump
----------
This function lets you easily version your cookbooks without having to manually edit the cookbook's `metadata.rb` file. You can either specify the version level you'd like to bump (`major`, `minor`, or `patch`), or you can manually specify a version number. This might be used if, for example, you want to jump several version numbers in one go and don't want to have to run knife bump once for each number. If no bump level is specified, a patch level bump will be performed.

#### Usage
```bash
knife spork bump COOKBOOK [major | minor | patch | manual x.x.x]
````

#### Example (No patch level specified - defaulting to patch)
```text
$ knife spork bump apache2
Successfully bumped apache2 to v2.0.4!
```

#### Example (Bumping patch level)
```text
$ knife spork bump apache2 patch
Successfully bumped apache2 to v2.0.4!
```

#### Example (Manually setting version)
```text
$ knife spork bump apache2 manual 1.0.13
Successfully bumped apache2 to v1.0.13!
```

Spork Upload
------------
This function works mostly the same as normal `knife cookbook upload COOKBOOK` except that this automatically freezes cookbooks when you upload them.

#### Usage
```bash
knife spork upload COOKBOOK
```
#### Example
```text
$ knife spork upload apache2
Freezing apache2 at 1.0.13...
Successfully uploaded apache2@1.0.13!
```

Spork Promote
-------------
This function lets you easily set a version constraint in an environment or group of environments for a particular cookbook. By default it will set the version constraint to whatever the local version of the specified cookbook is. Optionally, you can include a `--version` option which will set the version constraint for the specified cookbook to whatever version number you provide. You might want to use this if, for example, you pushed a version constraint for a cookbook version you don't want your nodes to use anymore, so you want to "roll back" the environment to a previous version. You can also specify the `--remote` option if you'd like to automatically upload your changed local environment file to the server. To promote to multiple environments, simply pass a list of them delimited with a comma.  

If you don't specify an environment or environment group, the default_environments config directive will be used if set.

#### Usage

```bash
knife spork promote [ENVIRONMENT OR ENVIRONMENT GROUP NAME] COOKBOOK [--version, --remote]
```

#### Example (Using local cookbook version number)

```text
$ knife spork promote my_environment apache2 --remote
Adding version constraint apache2 = 1.0.13
Saving changes to my_environment.json
Uploading my_environment to Chef Server
Promotion complete!
```

#### Example (Using manual version)
```text
$ knife spork promote my_environment apache2 -v 2.0.2
Adding version constraint apache2 = 2.0.2
Saving changes to my_environment.json
Promotion complete. Don't forget to upload your changed my_environment to Chef Server
```

Spork Delete
------------
This function works mostly the same as normal `knife cookbook delete COOKBOOK` including options to delete all versions and delete without interactive confirmation.

#### Usage
```bash
knife spork delete COOKBOOK
```
#### Example
```text
$ knife spork delete apache2 -a
WARNING: Deleting cookbook apache2...
Do you really want to delete all versions of apache2? (Y/N) Y
Deleted cookbook[apache2][2.0.2]
Successfully deleted cookbook apache2 ALL versions from the Chef server
Cookbooks deleted from Chef server: apache2: ALL versions
```

Spork Omni
-------------
Omni lets you combine one of the most common combinations of spork commands (bump, upload & promote or promote --remote) - into one handy shortcut.

As omni is designed for use only in those cases where you want to perform all three of bump, upload and promote at the same time it supports a limited subset of the command line options supported by the individual bump, upload and promote commands.

If you run omni with no extra options, it will default to performing a ```patch``` level bump, and promote locally to the environments listed in the ```default_environments``` variable in your spork configuration file.

Alternatively, you can specify any of the following options:

```--cookbook-path PATH:PATH```: A colon-separated path to look for cookbooks in

```--include-dependencies```: Also upload cookbook dependencies during the upload step

```--bump-level [major|minor|patch]```: Version level to bump the cookbook (defaults to patch)

```--environment ENVIRONMENT```: Environment to promote the cookbook to',

```--remote```: Make omni perform a promote --remote instead of a local promote',

#### Usage

```bash
knife spork omni COOKBOOK [--bump-level, --cookbook-path, --include-dependencies, --environment, --remote]
```

#### Example (default options, default_environments set to development and production)

```text
$ knife spork omni apache2
OMNI: Bumping apache2
Successfully bumped apache2 to v0.3.99!

OMNI: Uploading apache2
Freezing apache2 at 0.3.99...
Successfully uploaded apache2@0.3.99!

OMNI: Promoting apache2
Adding version constraint apache2 = 0.3.99
Saving changes to development.json
Promotion complete. Don't forget to upload your changed development.json to Chef Server
Adding version constraint apache2 = 0.3.99
Saving changes to production.json
Promotion complete. Don't forget to upload your changed production.json to Chef Server
```

#### Example (default options, default_environments set to development and production, promote --remote)

```text
$ knife spork omni apache2 --remote
OMNI: Bumping apache2
Successfully bumped apache2 to v0.3.99!

OMNI: Uploading apache2
Freezing apache2 at 0.3.99...
Successfully uploaded apache2@0.3.99!

OMNI: Promoting apache2
Adding version constraint apache2 = 0.3.99
Saving changes to development.json
Uploading development.json to Chef Server
Promotion complete at 2013-08-08 11:43:12 +0100!
Adding version constraint apache2 = 0.3.99
Saving changes to production.json
Uploading production.json to Chef Server
Promotion complete at 2013-08-08 11:43:12 +0100!
```

#### Example (Specifying patch level and environment)
```text
$ knife spork omni apache2 -l minor -e development
OMNI: Bumping apache2
Successfully bumped apache2 to v0.4.0!

OMNI: Uploading apache2
Freezing apache2 at 0.4.0...
Successfully uploaded apache2@0.4.0!

OMNI: Promoting apache2
Adding version constraint apache2 = 0.4.0
Saving changes to development.json
Promotion complete. Don't forget to upload your changed development.json to Chef Server
```

Spork Environment Check
-------------
Environment check provides the ability to validate a local chef environment file is locked to versions that actually exist on the chef server.  Running this check prior to uploading your environment files is recommended as it can prevent your chef server from becoming unresponsive due to a version constraint that will never be valid.

If you run environment check with no options it will collect all invalid cookbook versions before reporting a failure.

Alternatively, you can specify any of the following options:

```-f, --fatal```: Quit on first invalid constraint located

#### Usage

```bash
knife spork environment check ENVIRONMENT (options)
```

#### Example of a passing chef environment check with no options

```text
$ knife spork environment check production

Checking constraints for environment: production
Environment production looks good
```

#### Example of multiple invalid cookbooks with no options

```text
$ knife spork environment check production

Checking constraints for environment: production
ERROR: mysql@10.2.0 does not exist on Chef Server! Upload the cookbook first by running:

	knife spork upload mysql

ERROR: rbenv@10.7.1 does not exist on Chef Server! Upload the cookbook first by running:

	knife spork upload rbenv

FATAL: Environment production has constraints that point to non existent cookbook versions.
```

#### Example of running with the --fatal flag with the same invalid cookbooks from previous example

```text
$ knife spork environment check production

Checking constraints for environment: production
FATAL: mysql@10.2.0 does not exist on Chef Server! Upload the cookbook first by running:

	knife spork upload mysql
```

Spork Node / Role / Databag Commands
-------------

Knife spork contains "wrappers" around several stock knife commands for changing nodes, roles, environments and databags. These commands work exactly as in the original knife, with the addition of being wrapped in Spork's plugin API. This means that for example, when you upload a role using spork you will see an IRC message containing details, and a gist of the role change.

The following  ```data bag``` commands are provided in knife-spork:
```
knife spork data bag create
knife spork data bag delete
knife spork data bag edit
knife spork data bag from file
```

The following  ```node``` commands are provided in knife-spork:
```
knife spork node create
knife spork node delete
knife spork node edit
knife spork node from file
knife spork node run_list add
knife spork node run_list remove
knife spork node run_list set
```

The following  ```role``` commands are provided in knife-spork:
```
knife spork role create
knife spork role delete
knife spork role edit
knife spork role from file
```

The following  ```environment``` commands are provided in knife-spork:
```
knife spork environment create
knife spork environment delete
knife spork environment edit
knife spork environment from file
```

Troubleshooting
---------------
If you get an error when running `knife spork <command>` and the message shown when running with the `-VV` flag contains:
```ruby
undefined method `gsub' for #<Pathname:0x00000002d3a6b0> (NoMethodError)
```
...then you are probably using `Librarian::Chef.install_path()` in your `knife.rb` file.

To fix this you need to call `.to_s` on the install path, i.e. ``Librarian::Chef.install_path().to_s`.
