module Geocoder
  module Generators
    module MigrationVersion
      def rails_5?
        Rails::VERSION::MAJOR == 5
      end

      def migration_version
        if rails_5?
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end
    end
  end
end
