require "rails/generators/base"

module Administrate
  module Generators
    module Assets
      class StylesheetsGenerator < Rails::Generators::Base
        STYLESHEETS_PATH = "app/assets/stylesheets/administrate"

        source_root File.expand_path("../../../../../", __FILE__)

        def copy_stylesheets
          directory STYLESHEETS_PATH, STYLESHEETS_PATH
        end
      end
    end
  end
end
