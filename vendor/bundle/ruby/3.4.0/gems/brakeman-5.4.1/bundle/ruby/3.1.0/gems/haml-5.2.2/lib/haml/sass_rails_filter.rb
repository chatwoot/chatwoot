# frozen_string_literal: true

module Haml
  module Filters
    # This is an extension of Sass::Rails's SassTemplate class that allows
    # Rails's asset helpers to be used inside Haml Sass filter.
    class SassRailsTemplate < ::Sass::Rails::SassTemplate
      if Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('3.0.0')
        def render(scope=Object.new, locals={}, &block)
          environment = ::Sprockets::Railtie.build_environment(::Rails.application)
          scope = environment.context_class.new(
            environment: environment,
            filename: "/",
            metadata: {}
          )
          super
        end
      else
        def render(scope=Object.new, locals={}, &block)
          scope = ::Rails.application.assets.context_class.new(::Rails.application.assets, "/", "/")
          super
        end
      end

      def sass_options(scope)
        options = super
        options[:custom][:resolver] = ::ActionView::Base.new
        options
      end
    end

    # This is an extension of Sass::Rails's SassTemplate class that allows
    # Rails's asset helpers to be used inside a Haml SCSS filter.
    class ScssRailsTemplate < SassRailsTemplate
      self.default_mime_type = 'text/css'

      def syntax
        :scss
      end
    end

    remove_filter :Sass
    remove_filter :Scss
    register_tilt_filter "Sass", :extend => "Css", :template_class => SassRailsTemplate
    register_tilt_filter "Scss", :extend => "Css", :template_class => ScssRailsTemplate
  end
end
