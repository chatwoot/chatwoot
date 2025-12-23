require "administrate/view_generator"

module Administrate
  module Generators
    class AssetsGenerator < Administrate::ViewGenerator
      def copy_assets
        call_generator("administrate:assets:javascripts")
        call_generator("administrate:assets:stylesheets")
      end
    end
  end
end
