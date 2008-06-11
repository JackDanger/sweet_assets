require 'cgi'
require 'action_view/helpers/url_helper'
require 'action_view/helpers/tag_helper'
require 'digest/md5'

# USAGE:
# style_like :dolphins # assumes :media => 'all'
# style_like :home, :media => 'print'
# style_like :users, :media => ['print', 'screen']
# script_like :boats

module SweetAssets
  DEFAULT_JAVASCRIPTS = ['prototype', 'effects', 'dragdrop', 'controls']
  SCRIPT_PLACEHOLDER  = '<!--SWEET_JAVASCRIPTS-->'
  STYLE_PLACEHOLDER   = '<!--SWEET_STYLESHEETS-->'
  module ActionController
    def self.included(base)
      base.class_eval do
        extend  ClassMethods
        include InstanceMethods
        include AppendAssetsAfterRescue
        after_filter :apply_sweet_assets
      end
    end

    module ClassMethods
      def style_like(*assets)
        before_filter do |controller|
          controller.send :style_like, *assets
        end
      end

      def script_like(*assets)
        before_filter do |controller|
          controller.send :script_like, *assets
        end
      end
    end

    module InstanceMethods
      protected
        def style_like(*assets)
          sweet_assets.style_like(*assets)
        end
      
        def script_like(*assets)
          sweet_assets.script_like(*assets)
        end

        def sweet_assets
          @sweet_assets ||= SweetAssets::Request.new(self)
        end

        def apply_sweet_assets
          if response.body.respond_to?(:gsub!)
            response.body.gsub! SweetAssets::STYLE_PLACEHOLDER,  "\n#{sweet_assets.tags.stylesheets}"
            response.body.gsub! SweetAssets::SCRIPT_PLACEHOLDER, "\n#{sweet_assets.tags.javascripts}"
          end
        end
    end
  end

  module ActionView
    module Helpers
      def style_like(*assets)
        sweet_assets.style_like(*assets)
      end

      def script_like(*assets)
        sweet_assets.script_like(*assets)
      end
      
      def sweet_stylesheets
        SweetAssets::STYLE_PLACEHOLDER
      end
 
      def sweet_javascripts
        SweetAssets::SCRIPT_PLACEHOLDER
      end

      protected

        def sweet_assets
          controller.send :sweet_assets
        end
    end
  end

  class Request
    def initialize(controller)
      @stylesheets = Array.new
      @javascripts = Array.new
      @controller  = controller

      # use the assets named 'application'
      style_like :application
      script_like :application

      # use the assets named after the controller at higher priority
      style_like "#{@controller.class.controller_name}!"
      script_like "#{@controller.class.controller_name}!"
    end

    def style_like(*assets)
      options = HashWithIndifferentAccess.new(assets.extract_options!)
      media = [options[:media]].flatten.compact
      media = ['all'] if media.blank?
      media.each do |medium|
        medium = medium.to_s
        assets.each do |asset|
          asset = asset.to_s
          if asset.ends_with?('!')
            asset.gsub!(/!$/, '')
            # remove a lower-priority entry if it exists for this medium
            @stylesheets.delete({:file => asset, :medium => medium, :priority => 'low'})
            @stylesheets << {:file => asset, :medium => medium, :priority => 'high'}
          else
            # don't add this entry if it's already set to high-priority
            unless @stylesheets.include?({:file => asset, :medium => medium, :priority => 'high'})
              @stylesheets << {:file => asset, :medium => medium, :priority => 'low'}
            end
          end
        end
      end
    end

    def script_like(*assets)
      assets.each do |asset|
        asset = asset.to_s
        if 'defaults' == asset
          DEFAULT_JAVASCRIPTS.each do |default|
            @javascripts << {:file => default, :priority => 'first' }
          end
        elsif asset.ends_with?('!')
          asset.gsub!(/!$/, '')
          # remove a lower-priority entry if it exists
          @javascripts.delete({:file => asset, :priority => 'low'})
          @javascripts << {:file => asset, :priority => 'high'}
        else
          # don't add this entry if it's already set to high-priority
          unless @javascripts.include?({:file => asset, :priority => 'high'})
            @javascripts << {:file => asset, :priority => 'low'}
          end
        end
      end
    end
    
    def tags
      @tag_generator ||= TagGenerator.new(@stylesheets, @javascripts, @controller)
    end
  end

  class TagGenerator

    include ::ActionView::Helpers::TagHelper
    include ::ActionView::Helpers::AssetTagHelper

    def initialize(stylesheets, javascripts, controller)
      @stylesheets = stylesheets
      @javascripts = javascripts
      @controller  = controller
    end
    
    def stylesheets
      media = @stylesheets.map {|asset| asset[:medium] }.uniq

      media.map do |medium|
        files_in_order = ['low', 'high'].map do |priority|

          files = @stylesheets.select do |asset|
            asset[:medium] == medium && asset[:priority] == priority
          end
          files.map! {|asset| asset[:file] }
          files.map! {|file| file =~ /\.css$/ ? file : "#{file}.css" }

          # check that the files exist
          unless RAILS_ENV.eql?('test')
            files = files.select {|file| File.exists?("#{STYLESHEETS_DIR}/#{file}") }
          end
          
          files
        end.flatten.uniq.compact

        stylesheet_link_tag(*(files_in_order << {:media => medium, :cache => cached_file_name(files_in_order)}))

      end.join("\n")
    end

    def javascripts
      files_in_order = ['first', 'low', 'high'].map do |priority|

        files = @javascripts.select {|asset| asset[:priority] == priority }
        files.map! {|asset| asset[:file] }
        files.map! {|file| file =~ /\.js$/ ? file : "#{file}.js" }

        # check that the files exist
        unless RAILS_ENV.eql?('test')
          files = files.select {|file| File.exists?("#{JAVASCRIPTS_DIR}/#{file}") }
        end
        files
      end.flatten.uniq.compact

      files_in_order << {:cache => cached_file_name(files_in_order)}

      javascript_include_tag *files_in_order
    end

    protected
    
      def cached_file_name(filenames)
        "sweet_assets_#{Digest::MD5.hexdigest(filenames.join('_'))}"
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
        alias_method_chain :initialize, :append_sweet_assets_rescue_action unless respond_to?(:initialize_without_append_sweet_assets_rescue_action)
      end
    end
    
    def rescue_action_with_append_sweet_assets(*args)
      rescue_action_without_append_sweet_assets(*args)
       apply_sweet_assets
     end
   end
end
