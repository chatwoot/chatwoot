# The reason some options are declared here rather than in sass/plugin/configuration.rb
# is that otherwise they'd clobber the Rails-specific options.
# Since Rails' options are lazy-loaded in Rails 3,
# they're reverse-merged with the default options
# so that user configuration is preserved.
# This means that defaults that differ from Rails'
# must be declared here.

unless defined?(Sass::GENERIC_LOADED)
  Sass::GENERIC_LOADED = true

  Sass::Plugin.options.merge!(:css_location   => './public/stylesheets',
                              :always_update  => false,
                              :always_check   => true)
end
