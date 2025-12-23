# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'
require_relative '../generator_helpers'

module RubyLLM
  module Generators
    # Generator for RubyLLM Rails models and migrations
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      include RubyLLM::Generators::GeneratorHelpers

      namespace 'ruby_llm:install'

      source_root File.expand_path('templates', __dir__)

      argument :model_mappings, type: :array, default: [], banner: 'chat:ChatName message:MessageName ...'

      class_option :skip_active_storage, type: :boolean, default: false,
                                         desc: 'Skip ActiveStorage installation and attachment setup'

      desc 'Creates models and migrations for RubyLLM Rails integration\n' \
           'Usage: rails g ruby_llm:install [chat:ChatName] [message:MessageName] ...'

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_files
        migration_template 'create_chats_migration.rb.tt',
                           "db/migrate/create_#{chat_table_name}.rb"

        sleep 1 # Ensure different timestamp
        migration_template 'create_messages_migration.rb.tt',
                           "db/migrate/create_#{message_table_name}.rb"

        sleep 1 # Ensure different timestamp
        migration_template 'create_tool_calls_migration.rb.tt',
                           "db/migrate/create_#{tool_call_table_name}.rb"

        sleep 1 # Ensure different timestamp
        migration_template 'create_models_migration.rb.tt',
                           "db/migrate/create_#{model_table_name}.rb"

        sleep 1 # Ensure different timestamp
        migration_template 'add_references_to_chats_tool_calls_and_messages_migration.rb.tt',
                           'db/migrate/add_references_to_' \
                           "#{chat_table_name}_#{tool_call_table_name}_and_#{message_table_name}.rb"
      end

      def create_model_files
        create_namespace_modules

        template 'chat_model.rb.tt', "app/models/#{chat_model_name.underscore}.rb"
        template 'message_model.rb.tt', "app/models/#{message_model_name.underscore}.rb"
        template 'tool_call_model.rb.tt', "app/models/#{tool_call_model_name.underscore}.rb"

        template 'model_model.rb.tt', "app/models/#{model_model_name.underscore}.rb"
      end

      def create_initializer
        template 'initializer.rb.tt', 'config/initializers/ruby_llm.rb'
      end

      def install_active_storage
        return if options[:skip_active_storage]

        say '  Installing ActiveStorage for file attachments...', :cyan
        rails_command 'active_storage:install'
      end

      def show_install_info
        say "\n  ✅ RubyLLM installed!", :green

        say '  ✅ ActiveStorage configured for file attachments support', :green unless options[:skip_active_storage]

        say "\n  Next steps:", :yellow
        say '     1. Run: rails db:migrate'
        say '     2. Set your API keys in config/initializers/ruby_llm.rb'

        say "     3. Start chatting: #{chat_model_name}.create!(model: 'gpt-4.1-nano').ask('Hello!')"

        say "\n  🚀 Model registry is database-backed!", :cyan
        say '     Models automatically load from the database'
        say '     Pass model names as strings - RubyLLM handles the rest!'
        say "     Specify provider when needed: Chat.create!(model: 'gemini-2.5-flash', provider: 'vertexai')"

        if options[:skip_active_storage]
          say "\n  📎 Note: ActiveStorage was skipped", :yellow
          say '     File attachments won\'t work without ActiveStorage.'
          say '     To enable later:'
          say '       1. Run: rails active_storage:install && rails db:migrate'
          say "       2. Add to your #{message_model_name} model: has_many_attached :attachments"
        end

        say "\n  📚 Documentation: https://rubyllm.com", :cyan

        say "\n  ❤️  Love RubyLLM?", :magenta
        say '     • ⭐ Star on GitHub: https://github.com/crmne/ruby_llm'
        say '     • 🐦 Follow for updates: https://x.com/paolino'
        say "\n"
      end
    end
  end
end
