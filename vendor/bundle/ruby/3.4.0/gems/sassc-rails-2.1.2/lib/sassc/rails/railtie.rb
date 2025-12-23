# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'sprockets/railtie'

module SassC::Rails
  class Railtie < ::Rails::Railtie
    config.sass = ActiveSupport::OrderedOptions.new

    # Establish static configuration defaults
    # Emit scss files during stylesheet generation of scaffold
    config.sass.preferred_syntax = :scss
    # Initialize the load paths to an empty array
    config.sass.load_paths       = []

    # Display line comments above each selector as a debugging aid
    config.sass.line_comments    = true

    # Set the default stylesheet engine
    # It can be overridden by passing:
    #     --stylesheet_engine=sass
    # to the rails generate command
    config.app_generators.stylesheet_engine config.sass.preferred_syntax

    if config.respond_to?(:annotations)
      config.annotations.register_extensions("scss", "sass") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
    end

    # Remove the sass middleware if it gets inadvertently enabled by applications.
    config.after_initialize do |app|
      app.config.middleware.delete(Sass::Plugin::Rack) if defined?(Sass::Plugin::Rack)
    end

    initializer :setup_sass, group: :all do |app|
      # Only emit one kind of syntax because though we have registered two kinds of generators
      syntax     = app.config.sass.preferred_syntax.to_sym
      alt_syntax = syntax == :sass ? "scss" : "sass"
      app.config.generators.hide_namespace alt_syntax

      # Override stylesheet engine to the preferred syntax
      config.app_generators.stylesheet_engine syntax

      # Establish configuration defaults that are environmental in nature
      # if config.sass.full_exception.nil?
      #   # Display a stack trace in the css output when in development-like environments.
      #   config.sass.full_exception = app.config.consider_all_requests_local
      # end

      app.config.assets.configure do |env|
        env.context_class.class_eval do
          class_attribute :sass_config
          self.sass_config = app.config.sass
        end

        if env.respond_to?(:register_transformer)
          env.register_transformer 'text/sass', 'text/css', SassC::Rails::SassTemplate.new
          env.register_transformer 'text/scss', 'text/css', SassC::Rails::ScssTemplate.new
        end

        if env.respond_to?(:register_engine)
          [
            ['.sass', SassC::Rails::SassTemplate],
            ['.scss', SassC::Rails::ScssTemplate]
          ].each do |engine|
            engine << { silence_deprecation: true } if Sprockets::VERSION.start_with?("3")
            env.register_engine(*engine)
          end
        end
      end
    end

    initializer :setup_compression, group: :all do |app|
      if !Rails.env.development?
        app.config.assets.css_compressor = :sass unless app.config.assets.has_key?(:css_compressor)
      else
        # Use expanded output instead of the sass default of :nested unless specified
        app.config.sass.style ||= :expanded
      end
    end
  end
end
