# frozen_string_literal: true

module SassC
  # The global load paths for Sass files. This is meant for plugins and
  # libraries to register the paths to their Sass stylesheets to that they may
  # be `@imported`. This load path is used by every instance of {Sass::Engine}.
  # They are lower-precedence than any load paths passed in via the
  # {file:SASS_REFERENCE.md#load_paths-option `:load_paths` option}.
  #
  # If the `SASS_PATH` environment variable is set,
  # the initial value of `load_paths` will be initialized based on that.
  # The variable should be a colon-separated list of path names
  # (semicolon-separated on Windows).
  #
  # Note that files on the global load path are never compiled to CSS
  # themselves, even if they aren't partials. They exist only to be imported.
  #
  # @example
  #   SassC.load_paths << File.dirname(__FILE__ + '/sass')
  # @return [Array<String, Pathname, Sass::Importers::Base>]
  def self.load_paths
    @load_paths ||= if ENV['SASS_PATH']
                      ENV['SASS_PATH'].split(SassC::Util.windows? ? ';' : ':')
                    else
                      []
                    end
  end
end

require_relative "sassc/version"
require_relative "sassc/native"
require_relative "sassc/import_handler"
require_relative "sassc/importer"
require_relative "sassc/util"
require_relative "sassc/util/normalized_map"
require_relative "sassc/script"
require_relative "sassc/script/value"
require_relative "sassc/script/value/bool"
require_relative "sassc/script/value/number"
require_relative "sassc/script/value/color"
require_relative "sassc/script/value/string"
require_relative "sassc/script/value/list"
require_relative "sassc/script/value/map"
require_relative "sassc/script/functions"
require_relative "sassc/script/value_conversion"
require_relative "sassc/script/value_conversion/base"
require_relative "sassc/script/value_conversion/string"
require_relative "sassc/script/value_conversion/number"
require_relative "sassc/script/value_conversion/color"
require_relative "sassc/script/value_conversion/map"
require_relative "sassc/script/value_conversion/list"
require_relative "sassc/script/value_conversion/bool"
require_relative "sassc/functions_handler"
require_relative "sassc/dependency"
require_relative "sassc/error"
require_relative "sassc/engine"
require_relative "sassc/sass_2_scss"
