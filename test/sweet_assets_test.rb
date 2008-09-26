
RAILS_ENV = 'test'

require File.dirname(__FILE__) + '/../../../../config/environment'
require 'test/unit'
require 'rubygems'
require 'action_controller/test_process'
require File.dirname(__FILE__) + '/../init'

ActionController::Base.view_paths = [File.dirname(__FILE__) + '/views/']

# Re-raise errors caught by the controller.
class WebController < ActionController::Base
  style_like  :home
  style_like  :users!
  style_like  :extra
  script_like :home
  script_like :users!
  script_like :extra
end

class ShortcutController < ActionController::Base
  style_like :home!, :users
  script_like :extra!, :home
end

class DefaultsController < ActionController::Base
  script_like :defaults
end

class SweetAssetsTest < Test::Unit::TestCase

  def setup
    ActionController::Base.perform_caching = false
    @controller = WebController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def teardown
    delete_empty_recent_files
  end
  
  def test_each_stylesheet_should_appear
    get :index
    assert_response :success
    assert_tag :link, :attributes => {:href => /stylesheets\/application.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /stylesheets\/web.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /stylesheets\/home.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /stylesheets\/extra.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /stylesheets\/users.css/, :rel => 'stylesheet'}
    assert_select 'head > link', :count => 5
  end
  
  def test_bottom_stylesheets_should_appear_last
    get :index
    assert_response :success
    location_of_extra_css = @response.body =~ /<link href="\/stylesheets\/extra.css/
    location_of_home_css  = @response.body =~ /<link href="\/stylesheets\/home.css/
    location_of_users_css = @response.body =~ /<link href="\/stylesheets\/users.css/
    assert location_of_home_css < location_of_users_css
    assert location_of_extra_css < location_of_users_css
  end

  def test_caching_stylesheets
    ActionController::Base.perform_caching = true
    with_stylesheets :application, :home, :web, :users, :extra do
      with_javascripts :application, :home, :web, :users, :extra do
        get :index
      end
    end
    assert_response :success
    assert_no_tag :link, :attributes => {:href => /stylesheets\/application.css/, :rel => 'stylesheet'}
    assert_no_tag :link, :attributes => {:href => /stylesheets\/web.css/, :rel => 'stylesheet'}
    assert_no_tag :link, :attributes => {:href => /stylesheets\/home.css/, :rel => 'stylesheet'}
    assert_no_tag :link, :attributes => {:href => /stylesheets\/extra.css/, :rel => 'stylesheet'}
    assert_no_tag :link, :attributes => {:href => /stylesheets\/users.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /sweet_assets_([\w\d]{32}).css/, :rel => 'stylesheet'}
    ActionController::Base.perform_caching = false
  end

  def test_caching_javascripts
    ActionController::Base.perform_caching = true
    with_stylesheets :home, :web, :users, :extra do
      with_javascripts :home, :web, :users, :extra do
        get :index
      end
    end
    assert_response :success
    assert_no_tag :script, :attributes => {:src => /javascripts\/web.js/}
    assert_no_tag :script, :attributes => {:src => /javascripts\/home.js/}
    assert_no_tag :script, :attributes => {:src => /javascripts\/extra.js/}
    assert_no_tag :script, :attributes => {:src => /javascripts\/users.js/}
    assert_tag :script, :attributes => {:src => /sweet_assets_([\w\d]{32}).js/}
    ActionController::Base.perform_caching = false
  end
  
  def test_defaults_should_include_prototype_scriptaculous_and_application
    @controller = DefaultsController.new
    get :index
    assert_tag :script, :attributes => {:src => /prototype.js/}
    assert_tag :script, :attributes => {:src => /effects.js/}
    assert_tag :script, :attributes => {:src => /dragdrop.js/}
    assert_tag :script, :attributes => {:src => /controls.js/}
    assert_tag :script, :attributes => {:src => /application.js/}
  end
  
  def test_shortcuts
    @controller = ShortcutController.new
    with_stylesheets :home, :web, :users, :extra do
      with_javascripts :home, :web, :users, :extra do
        get :index
      end
    end
    assert_tag :link, :attributes => {:href => /home.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /users.css/, :rel => 'stylesheet'}
    assert_tag :script, :attributes => {:src => /extra.js/}
    assert_tag :script, :attributes => {:src => /home.js/}
    @controller = WebController.new
  end

  def delete_empty_recent_files
    dirs = ["#{RAILS_ROOT}/public/stylesheets", "#{RAILS_ROOT}/public/javascripts"]
    dirs.each do |dir|
      Dir.entries(dir).each do |file|
        if file =~ /(\.css|\.js)$/
          filename = File.join(dir, file)
          if File.exists?(filename) && File.read(filename).blank? && (File.ctime(filename) + 10.minutes) > Time.now
            File.delete(filename)
          end
        end
      end
    end
  end
  
  # create some temporary css files for the duration of the block
  def with_stylesheets(*files, &block)
    @temp_stylesheet_files = []
    files.each do |file|
      filename = "#{RAILS_ROOT}/public/stylesheets/#{file}.css"
      unless File.exists?(filename)
        @temp_stylesheet_files << "#{RAILS_ROOT}/public/stylesheets/#{file}.css"
        File.open(filename, 'w') {|f| f.write('') }
      end
    end
    
    yield
    
    @temp_stylesheet_files.each {|filename| File.delete(filename) }

  end
  
  # create some temporary javascript files for the duration of the block
  def with_javascripts(*files, &block)
    @temp_javascript_files = []
    files.each do |file|
      filename = "#{RAILS_ROOT}/public/javascripts/#{file}.js"
      unless File.exists?(filename)
        @temp_javascript_files << "#{RAILS_ROOT}/public/javascripts/#{file}.js"
        File.open(filename, 'w') {|f| f.write('') }
      end
    end
    
    yield

    @temp_javascript_files.each {|filename| File.delete(filename) }

  end
  
end
