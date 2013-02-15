## 1.0.17 (15th February, 2013)

Bugfixes:

    - Fix git plugin to work nicely with Cygwin and its unpredictable exit codes

## 1.0.16 (13th February, 2013)

Bugfixes:

    - Reverted broken foodcritic plugin to that in 1.0.14

## 1.0.15 (12th February, 2013)

Bugfixes:

    - Fixed git plugin so that when working on a submodule, submodules will be git pulled from the parent repo instead
    - Fixed foodcritic plugin bug where certain tag formats weren't being passed through

## 1.0.14 (15th January, 2013)

Features:

    -  Campfire plugin changed to use campy gem (thanks to Seth Vargo)
    -  Organization name now added to messages when present (thanks to Seth Vargo)
    -  Berkshelf support now added (thanks to Seth Vargo)

Bugfixes:

    - Promote won't try to create a version diff if there is no existing remote version (thanks to Seth Vargo)

## 1.0.13 (9th January, 2013)

Features:

    -  Made spork promote Use environment_path from spork config if it's set( thanks to Greg Karékinian - https://github.com/gkarekinian)

## 1.0.12 (22nd November, 2012)
Bugfixes:

    - Fix bug where cookbook dependancy loading broke in older chef client versions as a result of a fix in 1.0.10

## 1.0.11 (22nd November, 2012)

Yanked

## 1.0.10 (22nd November, 2012)
Bugfixes:

    - Load all cookbook versions from remote server when checking dependencies (thanks to gmcmillan)
    - Fix case where git plugin would update a previously loaded cookbook, resulting in out of data metadata being used. (thanks to zsol)

## 1.0.9 (28th October, 2012)
Features:

    -  Jabber Plugin (thanks to Graham McMillan - https://github.com/gmcmillan)

Bugfixes:

    - Fix exception when spork promote called with no arguments (thanks to Julian Dunn - https://github.com/juliandunn)
    
## 1.0.8 (25th September, 2012)
Bugfixes:

    - Fix whitespace warnings which occur in the git plugin under Ruby 1.8
    
## 1.0.7 (25th September, 2012)
Bugfixes:

    - Fix invalid syntax in Hipchat plugin
    
## 1.0.6 (25th September, 2012)
Bugfixes:

    - Fix for disabling plugins when override config files are present
    
## 1.0.5 (24th September, 2012)
Bugfixes:

    - Fixes for hipchat plugin
    
## 1.0.4 (14th September, 2012)
Features:

    - Spork can now run command from any directory, not just the root of your chef repository.
    
Bugfixes:

    - Fixed spork uploader to work more cleanly with 10.14.0 and greater
    - Spork bump will no longer throw errors when no cookbook name is specified
    
## 1.0.3 (10th September, 2012)
Bugfixes:

    - Fix spork upload when using Chef 10.14.0
    - Optional config override for chef environment location (not documented in README until 1.0.4)
    
## 1.0.2 (28th August, 2012)
Bugfixes:

    - Fix bug which caused plugin errors when no spork config file could be found
    
## 1.0.1 (27th August, 2012)
Bugfixes:

    - Fix require error which broke spork on CentOS 5.6
    
## 1.0.0 (27th August, 2012)
Features:

    - Major refactor (initial refactor: Seth Vargo)
    - Plugin API (Seth Vargo)
    - Added "spork info" command to show config hash and plugins status
    - Missing local / remote cookbook now handled nicely in spork check
    - Add "--fail" option to spork check to "exit 1" if check fails
    - Git plugin now uses git gem instead of shelling out
    - Confirmation check on promote if version jumps more than version_change_threshold
    - Thanks also to jperry, bethanybenzur and nickmarden for contributions submitted pre-refactor which have been included in one form or another.

    

## 0.1.11 (5th June, 2012)
Features:

    - Hipchat Support (courtesy of Chris Ferry: @cdferry)

Bugfixes:

    - Tweaks to spork bump to play nicely with x.x versions as well as x.x.x (courtesy of Russ Garrett: @russss)

## 0.1.10 (12th April, 2012)
Features:

    - All spork plugins now support multiple cookbook paths

Bugfixes:

    - Fixes to work with app_conf 0.4.0

## 0.1.9 (3rd April, 2012)

Features:

    - Spork Promote will now git add updated environment files if git is enabled
    - Spork Promote will optionally revert local changes to environment files if multiple changes were detected.
    - Spork Bump will now perform a git pull and pull from submodules if git is enabled
    - Optional Foodcritic integration added for Spork Upload
    - ickymettle's Eventinator service now optionally supported

Bugfixes:

    - Correct irccat alerts to not fire if cookbook upload fails
    - Code cleanup to remove unused Opscode code from Spork Upload

## 0.1.8 (21st February, 2012)

Features:

    - Make promote --remote check if the correct version of the cookbook has been uploaded before updating the remote environment

## 0.1.7 (21st February, 2012)

Bugfixes:

    - Make promote --remote work nicely when not run from chef repo root

## 0.1.6 (21st February, 2012)
Features:

    - Spork Bump now defaults to "patch" if bump level not specified
    - Spork Promote will prompt for confirmation if you're about to promote --remote changes to any cookbooks *other* than the one you specified on the command line. This should help avoid accidentally over-writing someone elses changes.
    - Irccat messages now support multiple channels
    - During promote, if git pull fails, ie a merge conflict has arisen, the error will be shown and promote will exit.
    - Spork Promote will now also update git submodules before promoting. Specifically, it will run "git submodule foreach git pull"
    - Failures during "git add" on spork bumps have a more helpful error message
    - Irccat messages are now more nicely formatted and have pretty colours.

Bugfixes:

    - Spork Promote will now work from anywhere in your chef repo, not just the repo root

## 0.1.5 (21st February, 2012)

Yanked

## 0.1.4 (3rd February, 2012)

Features:

    - Spork Check only show the last 5 remote versions, include the --all option if you want to see them all
    - Spork will no longer work with Ruby 1.8. If you're on that version, the plugin will bail immediately.
    - Spork now support updating a graphite metric when promote --remote is run
    - Spork now supports alerting using irccat when a cookbook upload or promote --remote happens
    - It will also optionally post a gist of version constraint changes in the above message when a promote --remote happens
    - Added support for default environments to promote to
    - knife-spork gemification thanks to Daniel Schauenberg

Bugfixes:

    - Various bugfixes and tweaks to formatting and log messages

## 0.1.4 (3rd February, 2012)

Yanked

## 0.1.3 (3rd February, 2012)

Yanked

## 0.1.2 (3rd February, 2012)

Yanked

## 0.1.1 (3rd February, 2012)

Yanked

## 0.1.0 (January 28, 2012)

Initial version.
