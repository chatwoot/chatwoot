# frozen_string_literal: true

require "erb"
require "securerandom"

require "sidekiq"
require "sidekiq/api"
require "sidekiq/paginator"
require "sidekiq/web/helpers"

require "sidekiq/web/router"
require "sidekiq/web/action"
require "sidekiq/web/application"
require "sidekiq/web/csrf_protection"

require "rack/content_length"
require "rack/builder"
require "rack/static"

module Sidekiq
  class Web
    ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../web")
    VIEWS = "#{ROOT}/views"
    LOCALES = ["#{ROOT}/locales"]
    LAYOUT = "#{VIEWS}/layout.erb"
    ASSETS = "#{ROOT}/assets"

    DEFAULT_TABS = {
      "Dashboard" => "",
      "Busy" => "busy",
      "Queues" => "queues",
      "Retries" => "retries",
      "Scheduled" => "scheduled",
      "Dead" => "morgue",
      "Metrics" => "metrics"
    }

    if Gem::Version.new(Rack::RELEASE) < Gem::Version.new("3")
      CONTENT_LANGUAGE = "Content-Language"
      CONTENT_SECURITY_POLICY = "Content-Security-Policy"
      LOCATION = "Location"
      X_CASCADE = "X-Cascade"
      X_CONTENT_TYPE_OPTIONS = "X-Content-Type-Options"
    else
      CONTENT_LANGUAGE = "content-language"
      CONTENT_SECURITY_POLICY = "content-security-policy"
      LOCATION = "location"
      X_CASCADE = "x-cascade"
      X_CONTENT_TYPE_OPTIONS = "x-content-type-options"
    end

    class << self
      def settings
        self
      end

      def default_tabs
        DEFAULT_TABS
      end

      def custom_tabs
        @custom_tabs ||= {}
      end
      alias_method :tabs, :custom_tabs

      def custom_job_info_rows
        @custom_job_info_rows ||= []
      end

      def locales
        @locales ||= LOCALES
      end

      def views
        @views ||= VIEWS
      end

      def enable(*opts)
        opts.each { |key| set(key, true) }
      end

      def disable(*opts)
        opts.each { |key| set(key, false) }
      end

      def middlewares
        @middlewares ||= []
      end

      def use(*args, &block)
        middlewares << [args, block]
      end

      def set(attribute, value)
        send(:"#{attribute}=", value)
      end

      attr_accessor :app_url, :redis_pool
      attr_writer :locales, :views
    end

    def self.inherited(child)
      child.app_url = app_url
      child.redis_pool = redis_pool
    end

    def settings
      self.class.settings
    end

    def middlewares
      @middlewares ||= self.class.middlewares
    end

    def use(*args, &block)
      middlewares << [args, block]
    end

    def call(env)
      env[:csp_nonce] = SecureRandom.base64(16)
      app.call(env)
    end

    def self.call(env)
      @app ||= new
      @app.call(env)
    end

    def app
      @app ||= build
    end

    def enable(*opts)
      opts.each { |key| set(key, true) }
    end

    def disable(*opts)
      opts.each { |key| set(key, false) }
    end

    def set(attribute, value)
      send(:"#{attribute}=", value)
    end

    # Register a class as a Sidekiq Web UI extension. The class should
    # provide one or more tabs which map to an index route. Options:
    #
    # @param extension [Class] Class which contains the HTTP actions, required
    # @param name [String] the name of the extension, used to namespace assets
    # @param tab [String | Array] labels(s) of the UI tabs
    # @param index [String | Array] index route(s) for each tab
    # @param root_dir [String] directory location to find assets, locales and views, typically `web/` within the gemfile
    # @param asset_paths [Array] one or more directories under {root}/assets/{name} to be publicly served, e.g. ["js", "css", "img"]
    # @param cache_for [Integer] amount of time to cache assets, default one day
    #
    # TODO name, tab and index will be mandatory in 8.0
    #
    # Web extensions will have a root `web/` directory with `locales/`, `assets/`
    # and `views/` subdirectories.
    def self.register(extension, name: nil, tab: nil, index: nil, root_dir: nil, cache_for: 86400, asset_paths: nil)
      tab = Array(tab)
      index = Array(index)
      tab.zip(index).each do |tab, index|
        tabs[tab] = index
      end
      if root_dir
        locdir = File.join(root_dir, "locales")
        locales << locdir if File.directory?(locdir)

        if asset_paths && name
          # if you have {root}/assets/{name}/js/scripts.js
          # and {root}/assets/{name}/css/styles.css
          # you would pass in:
          #   asset_paths: ["js", "css"]
          # See script_tag and style_tag in web/helpers.rb
          assdir = File.join(root_dir, "assets")
          assurls = Array(asset_paths).map { |x| "/#{name}/#{x}" }
          assetprops = {
            urls: assurls,
            root: assdir,
            cascade: true
          }
          assetprops[:header_rules] = [[:all, {Rack::CACHE_CONTROL => "private, max-age=#{cache_for.to_i}"}]] if cache_for
          middlewares << [[Rack::Static, assetprops], nil]
        end
      end

      yield self if block_given?
      extension.registered(WebApplication)
    end

    private

    def build
      klass = self.class
      m = middlewares

      rules = []
      rules = [[:all, {Rack::CACHE_CONTROL => "private, max-age=86400"}]] unless ENV["SIDEKIQ_WEB_TESTING"]

      ::Rack::Builder.new do
        use Rack::Static, urls: ["/stylesheets", "/images", "/javascripts"],
          root: ASSETS,
          cascade: true,
          header_rules: rules
        m.each { |middleware, block| use(*middleware, &block) }
        use Sidekiq::Web::CsrfProtection unless $TESTING
        run WebApplication.new(klass)
      end
    end
  end

  Sidekiq::WebApplication.helpers WebHelpers
  Sidekiq::WebApplication.helpers Sidekiq::Paginator

  Sidekiq::WebAction.class_eval <<-RUBY, __FILE__, __LINE__ + 1
    def _render
      #{ERB.new(File.read(Web::LAYOUT)).src}
    end
  RUBY
end
