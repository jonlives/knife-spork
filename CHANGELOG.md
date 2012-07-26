## 1.0.0 (21st July, 2012)
Features:
    - Major refactor
    - Plugin API

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
