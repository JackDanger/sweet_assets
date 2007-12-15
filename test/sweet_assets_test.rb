
RAILS_ENV='test'

require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + '/../../../../config/environment')
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')


# Re-raise errors caught by the controller.
class WebController < ActionController::Base
  before_filter :style_like_home
  before_filter :style_like_users!
  before_filter :style_like_extra
  before_filter :script_like_home
  before_filter :script_like_users!
  before_filter :script_like_extra
  def index
    render :text => '<html><head><title>SweetAssets</title></head><body></body></html>'
  end
end

class ShortcutController < ActionController::Base
  style_like :home!, :users
  script_like :extra!, :home
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
    assert_tag :link, :attributes => {:href => /stylesheets\/web.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /stylesheets\/home.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /stylesheets\/extra.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /stylesheets\/users.css/, :rel => 'stylesheet'}
    assert_select 'head > link', :count => 4
  end
  
  def test_bottom_stylesheets_should_appear_last
    get :index
    assert_response :success
    assert @response.body =~ /<link href="\/stylesheets\/users.css(\?\d*)?" media="screen" rel="stylesheet" type="text\/css" \/>\n*?<\/head>/
  end

  def test_caching_stylesheets
    ActionController::Base.perform_caching = true
    with_stylesheets :home, :web, :users, :extra do
      with_javascripts :home, :web, :users, :extra do
        get :index
      end
    end
    assert_response :success
    assert_no_tag :link, :attributes => {:href => /stylesheets\/web.css/, :rel => 'stylesheet'}
    assert_no_tag :link, :attributes => {:href => /stylesheets\/home.css/, :rel => 'stylesheet'}
    assert_no_tag :link, :attributes => {:href => /stylesheets\/extra.css/, :rel => 'stylesheet'}
    assert_no_tag :link, :attributes => {:href => /stylesheets\/users.css/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /sweet_stylesheets_home,extra.css(\?\d*)?/, :rel => 'stylesheet'}
    assert_tag :link, :attributes => {:href => /sweet_stylesheets_web,users.css(\?\d*)?/, :rel => 'stylesheet'}
    # and check the placement
    location_of_head = @response.body =~ /<head>/
    location_of_title = @response.body =~ /<title>/
    location_of_home_extra_css = @response.body =~ /<link href="\/stylesheets\/sweet_stylesheets_home,extra.css/
    location_of_web_users_css = @response.body =~ /<link href="\/stylesheets\/sweet_stylesheets_web,users.css/
    assert location_of_head < location_of_home_extra_css
    assert location_of_home_extra_css < location_of_title
    assert location_of_title < location_of_web_users_css
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
    assert_tag :script, :attributes => {:src => /sweet_javascripts_home,extra.js(\?\d*)?/}
    assert_tag :script, :attributes => {:src => /sweet_javascripts_web,users.js(\?\d*)?/}
    # and check the placement
    location_of_head = @response.body =~ /<head>/
    location_of_title = @response.body =~ /<title>/
    location_of_home_extra_js = @response.body =~ /<script src="\/javascripts\/sweet_javascripts_home,extra.js/
    location_of_web_users_js = @response.body =~ /<script src="\/javascripts\/sweet_javascripts_web,users.js/
    assert location_of_head < location_of_home_extra_js
    assert location_of_home_extra_js < location_of_title
    assert location_of_title < location_of_web_users_js
    ActionController::Base.perform_caching = false
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
