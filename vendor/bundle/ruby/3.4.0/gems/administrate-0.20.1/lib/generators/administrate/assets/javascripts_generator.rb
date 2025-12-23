require "rails/generators/base"

module Administrate
  module Generators
    module Assets
      class JavascriptsGenerator < Rails::Generators::Base
        JAVASCRIPTS_PATH = "app/assets/javascripts/administrate"

        source_root File.expand_path("../../../../../", __FILE__)

        def copy_javascripts
          directory JAVASCRIPTS_PATH, JAVASCRIPTS_PATH
        end
      end
    end
  end
end
