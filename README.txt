= SweetAssets

http://github.com/JackDanger/sweet_assets

== Description

  Automate adding stylesheets and javascripts to your controller actions

== Example

  Any controller will include the stylesheet and javascript source files named after named after the contorller if the file exists:
  
    class UsersController < ApplicationController
      ...
    end
    
    http://mysite.com/users/ will have /stylesheets/users.css and /javascripts/users.js included if they exist.
    
  Any controller can specify any other file to be added as a stylesheet:
  
    class UsersController < ApplicationController
      style_like :homes
      script_like :gargantuan
    end
    
    http://mysite.com/users/ will have users.css, homes.css and gargantuan.js included
    
  Any asset that needs to take precedence over others (i.e. should be linked after the other stylesheets) can be used with a bang (!)
  
    class UsersController < ApplicationController
      style_like :distort_reality!, :homes, :trees
      script_like :basic_script, :super_enhancement!
    end
    
    http://mysite.com/users/ will have homes.css, and trees.css and basic_script.js linked before the <title> tag.
    distort_reality.css and super_enhancement.js will be linked after the <title> tag.
    Note: the controller-named assets (users.css and users.js in this case) will always
    be applied with precedence.

  If you need better control over where these assets appear you can use the same options as you would for a before_filter
    
    class UsersController < ApplicationController
      style_like :homes!, :only => :show
      script_like :trees, :except => [:index, :show]
    end

  All linked assets will be cached into a single asset if caching is enabled.

Copyright (c) 2007 Jack Danger Canty of adPickles Inc, released under the MIT license
