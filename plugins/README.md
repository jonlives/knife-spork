Plugins Directory
=================
This folder contains relevant documentation for each KnifeSpork plugin. For more information, usage, and options for an particular plugin, click on the assoicated markdown file in the tree above.

Creating a Plugin
-----------------
To create a plugin, start with the following basic boiler template:

```ruby
require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class MyPlugin < Plugin
      name :my_plugin

      def perform
        # your plugin code here
      end
    end
  end
end
```

**Don't forget to update the class name and the `name` at the very top of the class!**

Helpers
-------
The following "helpers" or "methods" are exposed:

#### safe_require
This method allows you to safely require a gem. This is helpful when your plugin requires an external plugin. It will output a nice error message if the gem cannot be loaded and stop executing.

#### current_user
This method tries to get the current user's name in the following manner:

1. From the git configuration
2. From the `ENV`

#### config
This method returns the config associated with the current plugin. For example, if a `spork-config.yml` file looked like this:

```yaml
plugins:
  my_plugin:
    option_1: my_value
    option_2: other_value
```

then

```text
config.option_1   #=> 'my_value'
config.option_2   #=> 'other_value'
```

This uses `app_conf`, so you access the keys are methods, not `[]`.

#### cookbooks
This returns an array of `Chef::CookbookVersion` objects corresponding to the cookbooks that are being changed/altered in the hook. For more information on the methods avaliable, see the [file in the Chef repo](https://github.com/opscode/chef/blob/master/chef/lib/chef/cookbook_version.rb).

#### environments
This returns an array of `Chef::Environment` objects corresponding to the environments that are being changed/altered in the hook. For more information on the methods avaliable, see the [file in the Chef repo](https://github.com/opscode/chef/blob/master/chef/lib/chef/environment.rb).

#### environment_diffs
This returns a Hash of Hash objects containing a diff between local and remote environment for each environment changed/altered in the hook. Currently, this will only be populated during the promotea action. 


#### ui
This returns a `Chef::Knife::UI` element for outputting to the console. For more information on the methods avaliable, see the [file in the Chef repo](https://github.com/opscode/chef/blob/master/chef/lib/chef/knife/core/ui.rb).
