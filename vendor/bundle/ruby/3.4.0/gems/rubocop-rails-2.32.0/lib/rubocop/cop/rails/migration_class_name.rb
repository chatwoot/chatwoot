# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Makes sure that each migration file defines a migration class
      # whose name matches the file name.
      # (e.g. `20220224111111_create_users.rb` should define `CreateUsers` class.)
      #
      # @example
      #   # db/migrate/20220224111111_create_users.rb
      #
      #   # bad
      #   class SellBooks < ActiveRecord::Migration[7.0]
      #   end
      #
      #   # good
      #   class CreateUsers < ActiveRecord::Migration[7.0]
      #   end
      #
      class MigrationClassName < Base
        extend AutoCorrector
        include MigrationsHelper

        MSG = 'Replace with `%<camelized_basename>s` that matches the file name.'

        def on_class(node)
          return unless migration_class?(node)

          basename = basename_without_timestamp_and_suffix(processed_source.file_path)

          class_identifier = node.identifier.location.name
          camelized_basename = camelize(basename)
          return if class_identifier.source.casecmp(camelized_basename).zero?

          message = format(MSG, camelized_basename: camelized_basename)

          add_offense(class_identifier, message: message) do |corrector|
            corrector.replace(class_identifier, camelized_basename)
          end
        end

        private

        def basename_without_timestamp_and_suffix(filepath)
          basename = File.basename(filepath, '.rb')
          basename = remove_gem_suffix(basename)

          basename.sub(/\A\d+_/, '')
        end

        # e.g.: from `add_blobs.active_storage` to `add_blobs`.
        def remove_gem_suffix(file_name)
          file_name.sub(/\..+\z/, '')
        end

        def camelize(word)
          word.split('_').map(&:capitalize).join
        end
      end
    end
  end
end
