# frozen_string_literal: true

module Audited
  module Generators
    module MigrationHelper
      def migration_parent
        "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
