# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"
require "active_record"
require "rails/generators/active_record"
require "generators/audited/migration"
require "generators/audited/migration_helper"

module Audited
  module Generators
    class UpgradeGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      include Audited::Generators::MigrationHelper
      extend Audited::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      def copy_templates
        migrations_to_be_applied do |m|
          migration_template "#{m}.rb", "db/migrate/#{m}.rb"
        end
      end

      private

      def migrations_to_be_applied
        Audited::Audit.reset_column_information
        columns = Audited::Audit.columns.map(&:name)
        indexes = Audited::Audit.connection.indexes(Audited::Audit.table_name)

        yield :add_comment_to_audits unless columns.include?("comment")

        if columns.include?("changes")
          yield :rename_changes_to_audited_changes
        end

        unless columns.include?("remote_address")
          yield :add_remote_address_to_audits
        end

        unless columns.include?("request_uuid")
          yield :add_request_uuid_to_audits
        end

        unless columns.include?("association_id")
          if columns.include?("auditable_parent_id")
            yield :rename_parent_to_association
          else
            unless columns.include?("associated_id")
              yield :add_association_to_audits
            end
          end
        end

        if columns.include?("association_id")
          yield :rename_association_to_associated
        end

        if indexes.any? { |i| i.columns == %w[associated_id associated_type] }
          yield :revert_polymorphic_indexes_order
        end

        if indexes.any? { |i| i.columns == %w[auditable_type auditable_id] }
          yield :add_version_to_auditable_index
        end
      end
    end
  end
end
