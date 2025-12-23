module Sass
  module Plugin
    # Rack middleware for compiling Sass code.
    #
    # ## Activate
    #
    #     require 'sass/plugin/rack'
    #     use Sass::Plugin::Rack
    #
    # ## Customize
    #
    #     Sass::Plugin.options.merge!(
    #       :cache_location => './tmp/sass-cache',
    #       :never_update => environment != :production,
    #       :full_exception => environment != :production)
    #
    # {file:SASS_REFERENCE.md#Options See the Reference for more options}.
    #
    # ## Use
    #
    # Put your Sass files in `public/stylesheets/sass`.
    # Your CSS will be generated in `public/stylesheets`,
    # and regenerated every request if necessary.
    # The locations and frequency {file:SASS_REFERENCE.md#Options can be customized}.
    # That's all there is to it!
    class Rack
      # The delay, in seconds, between update checks.
      # Useful when many resources are requested for a single page.
      # `nil` means no delay at all.
      #
      # @return [Float]
      attr_accessor :dwell

      # Initialize the middleware.
      #
      # @param app [#call] The Rack application
      # @param dwell [Float] See \{#dwell}
      def initialize(app, dwell = 1.0)
        @app = app
        @dwell = dwell
        @check_after = Time.now.to_f
      end

      # Process a request, checking the Sass stylesheets for changes
      # and updating them if necessary.
      #
      # @param env The Rack request environment
      # @return [(#to_i, {String => String}, Object)] The Rack response
      def call(env)
        if @dwell.nil? || Time.now.to_f > @check_after
          Sass::Plugin.check_for_updates
          @check_after = Time.now.to_f + @dwell if @dwell
        end
        @app.call(env)
      end
    end
  end
end

require 'sass/plugin'
