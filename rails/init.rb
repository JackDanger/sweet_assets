require 'sweet_assets'


ActionController::Base.class_eval do
  include SweetAssets::ActionController
end

ActionView::Base.class_eval do
  include SweetAssets::ActionView::Helpers
end

