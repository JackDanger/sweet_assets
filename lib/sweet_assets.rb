require 'cgi'
require 'action_view/helpers/url_helper'
require 'action_view/helpers/tag_helper'

module SweetAssets
  PRIMARY_JAVASCRIPTS = [:prototype, :scriptaculous, :builder, :effects, :dragdrop, :controls, :slider, :sound, :application]

  class << self

    attr_accessor :use_primary_javascripts

    def included(base)
      base.class_eval do
        include AssignmentMethods
        include ClassMethods
        extend  SweetAssetsShortcuts
        include AppendAssetsAfterRescue
        before_filter :initialize_assets_accessor
        before_filter :apply_default_styles
        before_filter :apply_default_scripts
        after_filter  :apply_sweet_assets
      end
    end
  end


  module SweetAssetsShortcuts
    def style_like(*assets)
      options = assets.extract_options!
      before_filter Proc.new {|controller| controller.style_like *assets }, options
    end

    def script_like(*assets)
      options = assets.extract_options!
      before_filter Proc.new {|controller| controller.script_like *assets }, options
    end
  end
  
  module AssignmentMethods    
    def style_like(*styles)
      styles.each do |style|
        add_sweet_asset(style.to_s, :stylesheets)
      end
    end
    
    def script_like(*scripts)
      scripts.each do |script|
        script = script.to_s
        if 'defaults' == script
          SweetAssets.use_primary_javascripts = true
        else
          add_sweet_asset(script, :javascripts)
        end
      end
    end
    
    protected

      def add_sweet_asset(asset, collection)
        collection = sweet_assets[collection]
        if asset.ends_with?('!')
          asset.gsub!(/!$/, '')
          collection[:top].delete(asset)
          collection[:bottom] << asset
        else
          unless collection[:bottom].include?(asset)
            collection[:top] << asset
          end
        end
      end
    
      def sweet_assets
        self.is_a?(ActionView::Base) ?
          controller.instance_variable_get("@sweet_assets") :
          @sweet_assets
      end
  end
  
  module ClassMethods
    
    def method_missing_with_sweet_assets(method_name, *args, &block)
      
      if match = method_name.to_s.match(/^(style_like|script_like)_(\w+!?)$/)
        send match[1], match[2]
      else
        method_missing_without_sweet_assets(method_name, *args, &block)
      end
    end
    alias_method_chain :method_missing, :sweet_assets
    
    def initialize_assets_accessor
      @sweet_assets = { :javascripts => {:top => [], :bottom => []},
                        :stylesheets => {:top => [], :bottom => []} }
    end
    
    def apply_default_styles
      style_like :application
      style_like "#{controller_name}!"
    end

    def apply_default_scripts
      # we don't apply application.js by default because Rails already knows how to do that.
      script_like "#{controller_name}!"
    end

    def apply_sweet_assets
      return true unless @sweet_assets.any? {|asset_type, assets| assets.any? {|placement, files| !files.blank? } }
      generator = SweetAssetsGenerator.new(@sweet_assets, self)
      response.body.gsub! '<head>', "<head>\n#{generator.tags(:top)}\n" if response.body.respond_to?(:gsub!)
      response.body.gsub! '</head>', "\n#{generator.tags(:bottom)}\n</head>" if response.body.respond_to?(:gsub!)
      SweetAssets.use_primary_javascripts = false
      @sweet_assets = {}
    end
    
    class SweetAssetsGenerator
      
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::AssetTagHelper

      def initialize(assets, controller)
        @assets = assets
        @controller = controller
      end
      
      def tags(placement)
        javascript_tags(placement) + "\n" + stylesheet_tags(placement)
      end

      def stylesheet_tags(placement)
        files = @assets[:stylesheets][placement].dup
        files.uniq!
        files.map! {|file| file =~ /\.css$/ ? file : "#{file}.css" }
        files = files.select {|file| File.exists?("#{STYLESHEETS_DIR}/#{file}") } unless RAILS_ENV.eql?('test')
        return '' if files.blank?
        files << {:cache => "sweet_stylesheets_#{files.join(',')}" } if ActionController::Base.perform_caching
        stylesheet_link_tag *files
      end

      def javascript_tags(placement)
        files = @assets[:javascripts][placement].dup
        if SweetAssets.use_primary_javascripts
          files = SweetAssets::PRIMARY_JAVASCRIPTS + files
        end
        files.uniq!
        files.map! {|file| file =~ /\.js$/ ? file : "#{file}.js" }
        files = files.select {|file| File.exists?("#{JAVASCRIPTS_DIR}/#{file}") } unless RAILS_ENV.eql?('test')
        return '' if files.blank?
        files << {:cache => "sweet_javascripts_#{files.join(',')}" } if ActionController::Base.perform_caching
        javascript_include_tag *files
      end
    end
  end

  # we're going to wrap our rescue_action around the top-level rescue_action method chain
  # this ensures that we can apply the stylesheets even if the after filter was aborted due to an exception
  module AppendAssetsAfterRescue
    def self.included(base)
      base.class_eval do
        def initialize_with_append_sweet_assets_rescue_action(*args)
          initialize_without_append_sweet_assets_rescue_action(*args)
          self.class.send :alias_method_chain, :rescue_action, :append_sweet_assets unless respond_to?(:rescue_action_without_append_sweet_assets)
        end
        alias_method_chain :initialize, :append_sweet_assets_rescue_action
      end
    end
    
    def rescue_action_with_append_sweet_assets(*args)
      rescue_action_without_append_sweet_assets(*args)
      apply_sweet_assets
    end
  end
end