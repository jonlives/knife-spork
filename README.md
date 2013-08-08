KnifeSpork
===========
KnifeSpork is a workflow plugin for `Chef::Knife` which helps multiple developers work on the same Chef Server and repository without treading on each other's toes. This plugin was designed around the workflow we have here at Etsy, where several people are working on the Chef repository and Chef Server simultaneously. It contains several functions, documented below:

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

Spork Configuration
-------------------
Out of the box, knife spork will work with no configuration. However, you can optionally enable several features to enhance its functionality.

KnifeSpork will look for a configuration file in the following locations, in ascending order of precedence:

- `config/spork-config.yml`
- `/etc/spork-config.yml`
- `~/.chef/spork-config.yml`

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
environment_path: "/home/me/environments"
custom_plugin_path: "/home/me/spork-plugins"
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
  irccat:
    server: irccat.mydomain.com
    port: 12345
    gist: "/usr/bin/gist"
    channel: ["chef-annoucements"]
  graphite:
    server: graphite.mydomain.com
    port: 2003
  eventinator:
    url: http://eventinator.mydomain.com/events/oneshot
```

#### Default Environments
The `default_environments` directive allows you to specify a default list of environments you want to promote changes to. If this option is configured and you *omit* the environment parameter when promoting KnifeSpork will promote to all environments in this list.

#### Environment Groups
The `environment_groups` directive allows you to specify a list of environments referenced by group names that you want to promote changes to.

#### Version Change Threshold
The `version_change_threshold` directive allows you to customise the threshold used by a safety check in spork promote which will prompt for confirmation if you're promoting a cookbook by more than version_change_threshold versions. This defaults to 2 if not set, ie promoting a cookbook from v1.0.1 to v 1.0.2 will not trip this check, wheras promoting from v1.0.1 to v1.0.3 will.

#### Environment Path
The `environment_path` allows you to specify the path to where you store your chef environment json files. If this parameter is not specified, spork will default to using the first element of your cookbook_path, replacing the word "cookbooks" with "environments"

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
{"plugins"=>{"git"=>{"enabled"=>true}, "irccat"=>{"server"=>"irccat.mydomain.com", "port"=>12345, "gist"=>"usr/bin/gist", "channel"=>["#chef-announce"]}, "graphite"=>{"server"=>"graphite.mydomain.com", "port"=>2003}, "eventinator"=>{"url"=>"http://eventinator.mydomain.com/events/oneshot"}}, "default_environments"=>["development", "production"], "version_change_threshold"=>2, "pplugins"=>{"foodcritic"=>{"fail_tags"=>["style,correctness,test"], "tags"=>["~portability"], "include_rules"=>["config/rules.rb"]}}}

Plugins:
KnifeSpork::Plugins::Campfire: disabled
KnifeSpork::Plugins::Eventinator: enabled
KnifeSpork::Plugins::Foodcritic: disabled
KnifeSpork::Plugins::Git: enabled
KnifeSpork::Plugins::Graphite: enabled
KnifeSpork::Plugins::HipChat: disabled
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
This function lets you easily set a version constraint in an environment or group of environments for a particular cookbook. By default it will set the version constraint to whatever the local version of the specified cookbook is. Optionally, you can include a `--version` option which will set the version constraint for the specified cookbook to whatever version number you provide. You might want to use this if, for example, you pushed a version constraint for a cookbook version you don't want your nodes to use anymore, so you want to "roll back" the environment to a previous version. You can also specify the `--remote` option if you'd like to automatically upload your changed local environment file to the server.

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

