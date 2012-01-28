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

# Spork Check

This function is designed to help you avoid trampling on other people's cookbook versions, and to make sure that when you come to version your own work it's easy to see what version numbers have already been used and if the one you're using will overwrite anything.

## Usage 

````
knife spork check COOKBOOK
````

## Example (Checking an Unfrozen Cookbook with version clash)

````
$ knife spork check apache
Checking versions for cookbook apache...
 
Current local version: 0.1.0
 
Remote versions:
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
 
Remote versions:
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
 
Remote versions:
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

