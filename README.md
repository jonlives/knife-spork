KnifeSpork
===========
KnifeSpork is a workflow plugin for `Chef::Knife` which helps multiple developers work on the same Chef Server and repository without treading on eachother's toes. This plugin was designed around the workflow we have here at Etsy, where several people are working on the Chef repository and Chef Server simultaneously. It contains several functions, documented below:

Installation
------------
### Gem Install (recommended)
`knife-spork` is available on rubygems. Add the following to your `Gemfile`:

```ruby
gem 'knife-spork'
```

or install the gem manually:

```bash
gem install knife-spork
```

### Plugin Install
Copy spork-* script from lib/chef/knife/spork-*.rb to your ~/.chef/plugins/knife directory.

Spork Configuration
-------------------
Out of the box, knife spork will work with no configuration. However, you can optionally enable several features to enhance its functionality.

KnifeSpork will look for a configuration file in the following locations, in ascending order of precedence:

- `config/spork-config.yml`
- `/etc/spork-config.yml`
- `~/.chef/spork-config.yml`

Anything set in the configuration file in your home directory for example, will override options set in your Chef repository or `/etc`.

Below is a sample config file with all supported options enabled below, followed by an explanation of each section.

```yaml
default_environments:
  - development
  - production
version_change_threshold: 
plugins:
  campfire:
    account: myaccount
    token: a1b2c3d4...
```

#### Default Environments
The `default_environments` directive allows you to specify a default list of environments you want to promote changes to. If this option is configured and you *ommit* the environment parameter when promoting KnifeSpork will promote to all environments in this list.

#### Version Change Threshold
The `version_change_threshold` directive allows you to customise the threshold used by a safety check in spork promote which will prompt for confirmation if you're promoting a cookbook by more than version_change_threshold versions. This defaults to 2 if not set, ie promoting a cookbook from v1.0.1 to v 1.0.2 will not trip this check, wheras promoting from v1.0.1 to v1.0.3 will.

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
This function lets you easily version your cookbooks without having to manually edit the cookbook's `metadata.rb` file. You can either specify the version level you'd like to bump (`major`, `minor`, or `patch`), or you can manually specify a version number. This might be used if, for example, you want to jump several version numbers in one go and don't want to have to run knife bump once for each number.

#### Usage
```bash
knife spork bump COOKBOOK [MAJOR | MINOR | PATCH | MANUAL x.x.x]
````

#### Example (Bumping patch level)
```text
$ knife spork bump apache2 patch
Successfully bumped apache2 to v2.0.4!
````

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
This function lets you easily set a version constraint in an environment for a particular cookbook. By default it will set the version constraint to whatever the local version of the specified cookbook is. Optionally, you can include a `--version` option which will set the version constraint for the specified cookbook to whatever version number you provide. You might want to use this if, for example, you pushed a version constraint for a cookbook version you don't want your nodes to use anymore, so you want to "roll back" the environment to a previous version. You can also specify the `--remote` option if you'd like to automatically upload your changed local environment file to the server.

#### Usage

```bash
knife spork promote [ENVIRONMENT] COOKBOOK [--version, --remote]
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
