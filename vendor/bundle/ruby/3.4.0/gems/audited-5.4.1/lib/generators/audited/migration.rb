# frozen_string_literal: true

module Audited
  module Generators
    module Migration
      # Implement the required interface for Rails::Generators::Migration.
      def next_migration_number(dirname) # :nodoc:
        next_migration_number = current_migration_number(dirname) + 1
        if timestamped_migrations?
          [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % next_migration_number].max
        else
          "%.3d" % next_migration_number
        end
      end

      private

      def timestamped_migrations?
        (Rails.version >= "7.0") ?
          ::ActiveRecord.timestamped_migrations :
          ::ActiveRecord::Base.timestamped_migrations
      end
    end
  end
end
