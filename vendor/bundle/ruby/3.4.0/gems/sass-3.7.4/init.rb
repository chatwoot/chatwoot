begin
  require File.join(File.dirname(__FILE__), 'lib', 'sass') # From here
rescue LoadError
  begin
    require 'sass' # From gem
  rescue LoadError => e
    # gems:install may be run to install Haml with the skeleton plugin
    # but not the gem itself installed.
    # Don't die if this is the case.
    raise e unless defined?(Rake) &&
      (Rake.application.top_level_tasks.include?('gems') ||
        Rake.application.top_level_tasks.include?('gems:install'))
  end
end

# Load Sass.
# Sass may be undefined if we're running gems:install.
require 'sass/plugin' if defined?(Sass)
