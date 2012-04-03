# knife-spork

A workflow plugin for Chef::Knife which helps multiple devs work on the same chef server and repo without treading on eachothers toes. This plugin was designed around the workflow we have here at Etsy, where several people are working on the chef repo and chef server at the same time. It contains several functions, documented below:

# Installation

## SCRIPT INSTALL

Copy spork-* script from lib/chef/knife/spork-*.rb to your ~/.chef/plugins/knife directory.

## GEM INSTALL
knife-spork is available on rubygems.org - if you have that source in your gemrc, you can simply use:

````
gem install knife-spork
````

# Spork Configuration

Out of the box, knife spork will work with no configuration. However, you can optionally enable several features to enhance it's functionality.

Knife Spork will look for it's config file in the following locations, in ascending order of precedence.

* <chef-repo>/config/spork-config.yml
* /etc/spork-config.yml
* ~/.chef/spork-config.yml

Anything set in the config file in your home directory for example, will override options set in your chef repo or /etc.

Below is a sample config file with all supported options enabled below, followed by an explanation of each section.

````
git:
  enabled: true
irccat:
  enabled: true
  server: irccat.mycompany.com
  port: 12345
  channel: "#chef"
graphite:
  enabled: true
  server: graphite.mycompany.com
  port: 2003
gist:
  enabled: true
  in_chef: true
  chef_path: cookbooks/gist/files/default/gist
  path: /usr/bin/gist
foodcritic:
  enabled: true
  fail_tags: [any]
  tags: [foo]
  include_rules: [/home/me/myrules]
default_environments: [ production, development ]
````
## Git

This section enables a couple of git commands which will run as part of your spork workflow, namely:

* When you bump a cookbook's version, the relevant metadata.rb file will be git added
* When you promote an environment, git pull will be run before your changes are made.

## Irccat

If you're using the irccat (https://github.com/RJ/irccat) irc bot, this lets you post notifications to the channel of your choice. It currently notifies on

* When a cookbook is uploaded using spork upload
* When  an environment is promoted to the server using promote --remote

## Graphite

This lets you send to a graphite metric when promote --remote is performed. It send to the metric deploys.chef.<environment>
	
## Gist

This allows you to generate an optional gist of environment changes which will be added to irccat notifications on promote --remote. It supports the https://rubygems.org/gems/gist, and contains two parameters to use a version in your chef repo, or a version installed somewhere else locally.

## Foodcritic

This allows you to run a foodcritic lint check against your cookbook before spork uploading. The check only runs against the cookbook you've passed to spork-upload on the command line.

PLEASE NOTE: Due to it's many dependancies (gem dependancy Nokogiri requires libxml-devel, libxslt-devel), foodcritic is not specified as a dependency of the knife-spork gem as it won't install without other manual package installs, so if you want to use it you'll need to make sure it's installed yourself for now. This may change in a future version.

The optional attributes for this section work as follows:

fail_tags: Fail the build if any of the specified tags are matched.
tags: Only check against rules with the specified tags.
include_rules: Additional rule file path(s) to load.

## Default Environments

This allows you to specify a default list of environments you want to promote changes to. If this option is configured and you *ommit* the environment parameter when promoting, ie knife spork promote <cookbook>, then it will promote to all environments in this list.

# Spork Check

This function is designed to help you avoid trampling on other people's cookbook versions, and to make sure that when you come to version your own work it's easy to see what version numbers have already been used and if the one you're using will overwrite anything.

## Usage 

````
knife spork check COOKBOOK ( --all)
````

By default, spork check only shows the 5 most recent remote cookbook versions. Add the --all option if you want to see everything.

## Example (Checking an Unfrozen Cookbook with version clash)

````
$ knife spork check apache
Checking versions for cookbook apache...
 
Current local version: 0.1.0
 
Remote versions (Max. 5 most recent only):
*0.1.0, unfrozen
0.0.0, unfrozen
 
DANGER: Your local cookbook version number clashes with an unfrozen remote version.
 
If you upload now, you'll overwrite it.
````

## Example (Checking a Frozen Cookbook with version clash)

````
$ knife spork check apache2
Checking versions for cookbook apache2...
 
Current local version: 1.0.6
 
Remote versions (Max. 5 most recent only):
*1.0.6, frozen
1.0.5, frozen
1.0.4, frozen
1.0.3, frozen
1.0.2, frozen
1.0.1, frozen
1.0.0, frozen
 
DANGER: Your local cookbook has same version number as the starred version above!
 
Please bump your local version or you won't be able to upload.
````

## Example (No version clashes)

````
$ knife spork check apache2
Checking versions for cookbook apache2...
 
Current local version: 1.0.7
 
Remote versions (Max. 5 most recent only):
1.0.6, frozen
1.0.5, frozen
1.0.4, frozen
1.0.3, frozen
1.0.2, frozen
1.0.1, frozen
1.0.0, frozen
 
Everything looks fine, no version clashes. You can upload!
````

# Spork Bump

This function lets you easily version your cookbooks without having to manually edit the cookbook's metadata.rb file. You can either specify the version level you'd like to bump (major, minor or patch), or you can manually specify a version number. This might be used if, for example, you want to jump several version numbers in one go and don't want to have to run knife bump once for each number.

## Usage

````
knife bump COOKBOOK <MAJOR | MINOR | PATCH | MANUAL x.x.x>

````

## Example (Bumping patch level)

````
$ knife spork bump apache2 patch
Bumping patch level of the apache2 cookbook from 1.0.6 to 1.0.7
````

## Example (Manually setting version)

````
$ knife spork bump apache2 manual 1.0.13
Manually bumped version of the apache2 cookbook from 1.0.7 to 1.0.13
````

#Spork Upload

This function works mostly the same as normal "knife cookbook upload" except that this version automatically freezes cookbooks when you upload them. If you don't want to have to remember to add "--freeze" to your "knife cookbook upload" commands, then use this version.

## Usage

````
knife spork upload COOKBOOK
````

## Example

````
$ knife spork upload apache
 
Uploading and freezing apache             [1.0.6]
upload complete
````

# Spork Promote

This function lets you easily set a version constraint in an environment for a particular cookbook. By default it will set the version constraint to whatever the local version of the specified cookbook is. Optionally, you can include a --version option which will set the version constraint for the specified cookbook to whatever version number you provide. You might want to use this if, for example, you pushed a version constraint for a cookbook version you don't want your nodes to use anymore, so you want to "roll back" the environment to a previous version. You can also specify the --remote option if you'd like to automatically upload your changed local environment file to the server.

## Usage

```` 
knife spork promote ENVIRONMENT COOKBOOK (OPTIONS: --version, --remote)
````

## Example (Using local Cookbook version number, into environment "foo", uploading to chef server)

````
$ knife spork promote foo php --remote
Adding version constraint php = 0.1.0
 
Saving changes into foo.json

Uploading foo to server
 
Promotion complete! Please remember to upload your changed Environment file to the Chef Server.
````

## Example (Using manual version, into environment "foo", saving to local environment file only)

````
$ knife spork promote foo php -v 1.0.6
Adding version constraint php = 1.0.6
 
Saving changes into foo.json
 
Promotion complete! Please remember to upload your changed Environment file to the Chef Server.
````

