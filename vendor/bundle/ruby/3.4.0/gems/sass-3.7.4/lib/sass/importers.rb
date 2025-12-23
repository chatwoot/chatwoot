module Sass
  # Sass importers are in charge of taking paths passed to `@import`
  # and finding the appropriate Sass code for those paths.
  # By default, this code is always loaded from the filesystem,
  # but importers could be added to load from a database or over HTTP.
  #
  # Each importer is in charge of a single load path
  # (or whatever the corresponding notion is for the backend).
  # Importers can be placed in the {file:SASS_REFERENCE.md#load_paths-option `:load_paths` array}
  # alongside normal filesystem paths.
  #
  # When resolving an `@import`, Sass will go through the load paths
  # looking for an importer that successfully imports the path.
  # Once one is found, the imported file is used.
  #
  # User-created importers must inherit from {Importers::Base}.
  module Importers
  end
end

require 'sass/importers/base'
require 'sass/importers/filesystem'
require 'sass/importers/deprecated_path'
