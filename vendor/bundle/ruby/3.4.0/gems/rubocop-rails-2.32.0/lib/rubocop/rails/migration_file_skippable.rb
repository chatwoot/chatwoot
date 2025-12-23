# frozen_string_literal: true

module RuboCop
  module Rails
    # This module allows cops to detect and ignore files that have already been migrated
    # by leveraging the `AllCops: MigratedSchemaVersion` configuration.
    #
    # [source,yaml]
    # -----
    # AllCops:
    #   MigratedSchemaVersion: '20241225000000'
    # -----
    #
    # When applied to cops, it overrides the `add_global_offense` and `add_offense` methods,
    # ensuring that cops skip processing if the file is determined to be a migrated file
    # based on the schema version.
    #
    # @api private
    module MigrationFileSkippable
      def add_global_offense(message = nil, severity: nil)
        return if already_migrated_file?

        super if method(__method__).super_method
      end

      def add_offense(node_or_range, message: nil, severity: nil, &block)
        return if already_migrated_file?

        super if method(__method__).super_method
      end

      def self.apply_to_cops!
        RuboCop::Cop::Registry.all.each { |cop| cop.prepend(MigrationFileSkippable) }
      end

      private

      def already_migrated_file?
        return false unless migrated_schema_version

        match_data = File.basename(processed_source.file_path).match(/(?<timestamp>\d{14})/)
        schema_version = match_data['timestamp'] if match_data

        return false unless schema_version

        schema_version <= migrated_schema_version.to_s # Ignore applied migration files.
      end

      def migrated_schema_version
        @migrated_schema_version ||= config.for_all_cops.fetch('MigratedSchemaVersion', nil)
      end
    end
  end
end
