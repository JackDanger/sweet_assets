require 'sweet_assets'

ActionController::Base.send :include, SweetAssets
ActionView::Base.send :include, SweetAssets::AssignmentMethods

