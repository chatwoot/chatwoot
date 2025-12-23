# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'
require_relative '../generator_helpers'

module RubyLLM
  module Generators
    # Generator to upgrade existing RubyLLM apps to v1.7 with new Rails-like API
    class UpgradeToV17Generator < Rails::Generators::Base
      include Rails::Generators::Migration
      include RubyLLM::GeneratorHelpers

      namespace 'ruby_llm:upgrade_to_v1_7'
      source_root File.expand_path('templates', __dir__)

      # Override source_paths to include install templates
      def self.source_paths
        [
          File.expand_path('templates', __dir__),
          File.expand_path('../install/templates', __dir__)
        ]
      end

      argument :model_mappings, type: :array, default: [], banner: 'chat:ChatName message:MessageName ...'

      desc 'Upgrades existing RubyLLM apps to v1.7 with new Rails-like API\n' \
           'Usage: rails g ruby_llm:upgrade_to_v1_7 [chat:ChatName] [message:MessageName] ...'

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        @model_table_already_existed = table_exists?(table_name_for(model_model_name))

        # First check if models table exists, if not create it
        unless @model_table_already_existed
          migration_template 'create_models_migration.rb.tt',
                             "db/migrate/create_#{table_name_for(model_model_name)}.rb",
                             migration_version: migration_version,
                             model_model_name: model_model_name

          sleep 1 # Ensure different timestamp
        end

        migration_template 'migration.rb.tt',
                           'db/migrate/migrate_to_ruby_llm_model_references.rb',
                           migration_version: migration_version,
                           chat_model_name: chat_model_name,
                           message_model_name: message_model_name,
                           tool_call_model_name: tool_call_model_name,
                           model_model_name: model_model_name,
                           model_table_already_existed: @model_table_already_existed
      end

      def create_model_file
        create_namespace_modules

        template 'model_model.rb.tt', "app/models/#{model_model_name.underscore}.rb"
      end

      def update_existing_models
        update_model_acts_as(chat_model_name, 'acts_as_chat', acts_as_chat_declaration)
        update_model_acts_as(message_model_name, 'acts_as_message', acts_as_message_declaration)
        update_model_acts_as(tool_call_model_name, 'acts_as_tool_call', acts_as_tool_call_declaration)
      end

      def update_initializer
        initializer_path = 'config/initializers/ruby_llm.rb'

        unless File.exist?(initializer_path)
          say_status :warning, 'No initializer found. Creating one...', :yellow
          template 'initializer.rb.tt', initializer_path
          return
        end

        initializer_content = File.read(initializer_path)

        return if initializer_content.include?('config.use_new_acts_as')

        inject_into_file initializer_path, before: /^end/ do
          lines = ["\n  # Enable the new Rails-like API", '  config.use_new_acts_as = true']
          lines << "  config.model_registry_class = \"#{model_model_name}\"" if model_model_name != 'Model'
          lines << "\n"
          lines.join("\n")
        end
      end

      def show_next_steps
        say_status :success, 'Upgrade prepared!', :green
        say <<~INSTRUCTIONS

          Next steps:
          1. Review the generated migrations
          2. Run: rails db:migrate
          3. Update your code to use the new API: #{chat_model_name}.create! now has the same signature as RubyLLM.chat

          ⚠️  If you get "undefined method 'acts_as_model'" during migration:
            Add this to config/application.rb BEFORE your Application class:

            RubyLLM.configure do |config|
              config.use_new_acts_as = true
            end

          📚 See the full migration guide: https://rubyllm.com/upgrading-to-1-7/

        INSTRUCTIONS
      end

      private

      def update_model_acts_as(model_name, old_acts_as, new_acts_as)
        model_path = "app/models/#{model_name.underscore}.rb"
        return unless File.exist?(Rails.root.join(model_path))

        content = File.read(Rails.root.join(model_path))
        return unless content.match?(/^\s*#{old_acts_as}/)

        gsub_file model_path, /^\s*#{old_acts_as}.*$/, "  #{new_acts_as}"
      end
    end
  end
end
