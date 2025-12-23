require 'fileutils'

require 'sass'
require 'sass/plugin/compiler'

module Sass
  # This module provides a single interface to the compilation of Sass/SCSS files
  # for an application. It provides global options and checks whether CSS files
  # need to be updated.
  #
  # This module is used as the primary interface with Sass
  # when it's used as a plugin for various frameworks.
  # All Rack-enabled frameworks are supported out of the box.
  # The plugin is
  # {file:SASS_REFERENCE.md#Rack_Rails_Merb_Plugin automatically activated for Rails and Merb}.
  # Other frameworks must enable it explicitly; see {Sass::Plugin::Rack}.
  #
  # This module has a large set of callbacks available
  # to allow users to run code (such as logging) when certain things happen.
  # All callback methods are of the form `on_#{name}`,
  # and they all take a block that's called when the given action occurs.
  #
  # Note that this class proxies almost all methods to its {Sass::Plugin::Compiler} instance.
  # See \{#compiler}.
  #
  # @example Using a callback
  #   Sass::Plugin.on_updating_stylesheet do |template, css|
  #     puts "Compiling #{template} to #{css}"
  #   end
  #   Sass::Plugin.update_stylesheets
  #     #=> Compiling app/sass/screen.scss to public/stylesheets/screen.css
  #     #=> Compiling app/sass/print.scss to public/stylesheets/print.css
  #     #=> Compiling app/sass/ie.scss to public/stylesheets/ie.css
  # @see Sass::Plugin::Compiler
  module Plugin
    extend self

    @checked_for_updates = false

    # Whether or not Sass has **ever** checked if the stylesheets need to be updated
    # (in this Ruby instance).
    #
    # @return [Boolean]
    attr_accessor :checked_for_updates

    # Same as \{#update\_stylesheets}, but respects \{#checked\_for\_updates}
    # and the {file:SASS_REFERENCE.md#always_update-option `:always_update`}
    # and {file:SASS_REFERENCE.md#always_check-option `:always_check`} options.
    #
    # @see #update_stylesheets
    def check_for_updates
      return unless !Sass::Plugin.checked_for_updates ||
          Sass::Plugin.options[:always_update] || Sass::Plugin.options[:always_check]
      update_stylesheets
    end

    # Returns the singleton compiler instance.
    # This compiler has been pre-configured according
    # to the plugin configuration.
    #
    # @return [Sass::Plugin::Compiler]
    def compiler
      @compiler ||= Compiler.new
    end

    # Updates out-of-date stylesheets.
    #
    # Checks each Sass/SCSS file in
    # {file:SASS_REFERENCE.md#template_location-option `:template_location`}
    # to see if it's been modified more recently than the corresponding CSS file
    # in {file:SASS_REFERENCE.md#css_location-option `:css_location`}.
    # If it has, it updates the CSS file.
    #
    # @param individual_files [Array<(String, String)>]
    #   A list of files to check for updates
    #   **in addition to those specified by the
    #   {file:SASS_REFERENCE.md#template_location-option `:template_location` option}.**
    #   The first string in each pair is the location of the Sass/SCSS file,
    #   the second is the location of the CSS file that it should be compiled to.
    def update_stylesheets(individual_files = [])
      return if options[:never_update]
      compiler.update_stylesheets(individual_files)
    end

    # Updates all stylesheets, even those that aren't out-of-date.
    # Ignores the cache.
    #
    # @param individual_files [Array<(String, String)>]
    #   A list of files to check for updates
    #   **in addition to those specified by the
    #   {file:SASS_REFERENCE.md#template_location-option `:template_location` option}.**
    #   The first string in each pair is the location of the Sass/SCSS file,
    #   the second is the location of the CSS file that it should be compiled to.
    # @see #update_stylesheets
    def force_update_stylesheets(individual_files = [])
      Compiler.new(
        options.dup.merge(
          :never_update => false,
          :always_update => true,
          :cache => false)).update_stylesheets(individual_files)
    end

    # All other method invocations are proxied to the \{#compiler}.
    #
    # @see #compiler
    # @see Sass::Plugin::Compiler
    def method_missing(method, *args, &block)
      if compiler.respond_to?(method)
        compiler.send(method, *args, &block)
      else
        super
      end
    end

    # For parity with method_missing
    def respond_to?(method)
      super || compiler.respond_to?(method)
    end

    # There's a small speedup by not using method missing for frequently delegated methods.
    def options
      compiler.options
    end
  end
end

if defined?(ActionController)
  # On Rails 3+ the rails plugin is loaded at the right time in railtie.rb
  require 'sass/plugin/rails' unless Sass::Util.ap_geq_3?
elsif defined?(Merb::Plugins)
  require 'sass/plugin/merb'
else
  require 'sass/plugin/generic'
end
