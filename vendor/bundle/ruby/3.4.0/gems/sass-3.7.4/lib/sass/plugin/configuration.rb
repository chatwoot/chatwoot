module Sass
  module Plugin
    # We keep configuration in its own self-contained file so that we can load
    # it independently in Rails 3, where the full plugin stuff is lazy-loaded.
    #
    # Note that this is not guaranteed to be thread-safe. For guaranteed thread
    # safety, use a separate {Sass::Plugin} for each thread.
    module Configuration
      # Returns the default options for a {Sass::Plugin::Compiler}.
      #
      # @return [{Symbol => Object}]
      def default_options
        @default_options ||= {
          :css_location       => './public/stylesheets',
          :always_update      => false,
          :always_check       => true,
          :full_exception     => true,
          :cache_location     => ".sass-cache"
        }.freeze
      end

      # Resets the options and
      # {Sass::Callbacks::InstanceMethods#clear_callbacks! clears all callbacks}.
      def reset!
        @options = nil
        clear_callbacks!
      end

      # An options hash. See {file:SASS_REFERENCE.md#Options the Sass options
      # documentation}.
      #
      # @return [{Symbol => Object}]
      def options
        @options ||= default_options.dup
      end

      # Adds a new template-location/css-location mapping.
      # This means that Sass/SCSS files in `template_location`
      # will be compiled to CSS files in `css_location`.
      #
      # This is preferred over manually manipulating the
      # {file:SASS_REFERENCE.md#template_location-option `:template_location` option}
      # since the option can be in multiple formats.
      #
      # Note that this method will change `options[:template_location]`
      # to be in the Array format.
      # This means that even if `options[:template_location]`
      # had previously been a Hash or a String,
      # it will now be an Array.
      #
      # @param template_location [String] The location where Sass/SCSS files will be.
      # @param css_location [String] The location where compiled CSS files will go.
      def add_template_location(template_location, css_location = options[:css_location])
        normalize_template_location!
        template_location_array << [template_location, css_location]
      end

      # Removes a template-location/css-location mapping.
      # This means that Sass/SCSS files in `template_location`
      # will no longer be compiled to CSS files in `css_location`.
      #
      # This is preferred over manually manipulating the
      # {file:SASS_REFERENCE.md#template_location-option `:template_location` option}
      # since the option can be in multiple formats.
      #
      # Note that this method will change `options[:template_location]`
      # to be in the Array format.
      # This means that even if `options[:template_location]`
      # had previously been a Hash or a String,
      # it will now be an Array.
      #
      # @param template_location [String]
      #   The location where Sass/SCSS files were,
      #   which is now going to be ignored.
      # @param css_location [String]
      #   The location where compiled CSS files went, but will no longer go.
      # @return [Boolean]
      #   Non-`nil` if the given mapping already existed and was removed,
      #   or `nil` if nothing was changed.
      def remove_template_location(template_location, css_location = options[:css_location])
        normalize_template_location!
        template_location_array.delete([template_location, css_location])
      end

      # Returns the template locations configured for Sass
      # as an array of `[template_location, css_location]` pairs.
      # See the {file:SASS_REFERENCE.md#template_location-option `:template_location` option}
      # for details.
      #
      # Modifications to the returned array may not be persistent.  Use {#add_template_location}
      # and {#remove_template_location} instead.
      #
      # @return [Array<(String, String)>]
      #   An array of `[template_location, css_location]` pairs.
      def template_location_array
        convert_template_location(options[:template_location], options[:css_location])
      end

      private

      # Returns the given template location, as an array. If it's already an array,
      # it is returned unmodified. Otherwise, a new array is created and returned.
      #
      # @param template_location [String, Array<(String, String)>]
      #   A single template location, or a pre-normalized array of template
      #   locations and CSS locations.
      # @param css_location [String?]
      #   The location for compiled CSS files.
      # @return [Array<(String, String)>]
      #   An array of `[template_location, css_location]` pairs.
      def convert_template_location(template_location, css_location)
        return template_location if template_location.is_a?(Array)

        case template_location
        when nil
          if css_location
            [[File.join(css_location, 'sass'), css_location]]
          else
            []
          end
        when String
          [[template_location, css_location]]
        else
          template_location.to_a
        end
      end

      def normalize_template_location!
        options[:template_location] = convert_template_location(
          options[:template_location], options[:css_location])
      end
    end
  end
end
