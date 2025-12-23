unless defined?(Sass::MERB_LOADED)
  Sass::MERB_LOADED = true

  module Sass::Plugin::Configuration
    # Different default options in a m environment.
    def default_options
      @default_options ||= begin
        version = Merb::VERSION.split('.').map {|n| n.to_i}
        if version[0] <= 0 && version[1] < 5
          root = MERB_ROOT
          env  = MERB_ENV
        else
          root = Merb.root.to_s
          env  = Merb.environment
        end

        {
          :always_update     => false,
          :template_location => root + '/public/stylesheets/sass',
          :css_location      => root + '/public/stylesheets',
          :cache_location    => root + '/tmp/sass-cache',
          :always_check      => env != "production",
          :quiet             => env != "production",
          :full_exception    => env != "production"
        }.freeze
      end
    end
  end

  config = Merb::Plugins.config[:sass] || Merb::Plugins.config["sass"] || {}

  if defined? config.symbolize_keys!
    config.symbolize_keys!
  end

  Sass::Plugin.options.merge!(config)

  require 'sass/plugin/rack'
  class Sass::Plugin::MerbBootLoader < Merb::BootLoader
    after Merb::BootLoader::RackUpApplication

    def self.run
      # Apparently there's no better way than this to add Sass
      # to Merb's Rack stack.
      Merb::Config[:app] = Sass::Plugin::Rack.new(Merb::Config[:app])
    end
  end
end
