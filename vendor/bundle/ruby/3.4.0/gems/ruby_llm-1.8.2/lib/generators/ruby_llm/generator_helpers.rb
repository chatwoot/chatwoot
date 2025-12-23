# frozen_string_literal: true

module RubyLLM
  module Generators
    # Shared helpers for RubyLLM generators
    module GeneratorHelpers
      def parse_model_mappings
        @model_names = {
          chat: 'Chat',
          message: 'Message',
          tool_call: 'ToolCall',
          model: 'Model'
        }

        model_mappings.each do |mapping|
          if mapping.include?(':')
            key, value = mapping.split(':', 2)
            @model_names[key.to_sym] = value.classify
          end
        end

        @model_names
      end

      %i[chat message tool_call model].each do |type|
        define_method("#{type}_model_name") do
          @model_names ||= parse_model_mappings
          @model_names[type]
        end

        define_method("#{type}_table_name") do
          table_name_for(send("#{type}_model_name"))
        end

        define_method("#{type}_variable_name") do
          variable_name_for(send("#{type}_model_name"))
        end

        define_method("#{type}_controller_class_name") do
          controller_class_name_for(send("#{type}_model_name"))
        end

        define_method("#{type}_job_class_name") do
          "#{variable_name_for(send("#{type}_model_name")).camelize}ResponseJob"
        end

        define_method("#{type}_partial") do
          partial_path_for(send("#{type}_model_name"))
        end
      end

      def acts_as_chat_declaration
        params = []

        add_association_params(params, :messages, message_table_name, message_model_name, plural: true)
        add_association_params(params, :model, model_table_name, model_model_name)

        "acts_as_chat#{" #{params.join(', ')}" if params.any?}"
      end

      def acts_as_message_declaration
        params = []

        add_association_params(params, :chat, chat_table_name, chat_model_name)
        add_association_params(params, :tool_calls, tool_call_table_name, tool_call_model_name, plural: true)
        add_association_params(params, :model, model_table_name, model_model_name)

        "acts_as_message#{" #{params.join(', ')}" if params.any?}"
      end

      def acts_as_model_declaration
        params = []

        add_association_params(params, :chats, chat_table_name, chat_model_name, plural: true)

        "acts_as_model#{" #{params.join(', ')}" if params.any?}"
      end

      def acts_as_tool_call_declaration
        params = []

        add_association_params(params, :message, message_table_name, message_model_name)

        "acts_as_tool_call#{" #{params.join(', ')}" if params.any?}"
      end

      def create_namespace_modules
        namespaces = []

        [chat_model_name, message_model_name, tool_call_model_name, model_model_name].each do |model_name|
          if model_name.include?('::')
            namespace = model_name.split('::').first
            namespaces << namespace unless namespaces.include?(namespace)
          end
        end

        namespaces.each do |namespace|
          module_path = "app/models/#{namespace.underscore}.rb"
          next if File.exist?(Rails.root.join(module_path))

          create_file module_path do
            <<~RUBY
              module #{namespace}
                def self.table_name_prefix
                  "#{namespace.underscore}_"
                end
              end
            RUBY
          end
        end
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end

      def postgresql?
        ::ActiveRecord::Base.connection.adapter_name.downcase.include?('postgresql')
      rescue StandardError
        false
      end

      def table_exists?(table_name)
        ::ActiveRecord::Base.connection.table_exists?(table_name)
      rescue StandardError
        false
      end

      private

      def add_association_params(params, default_assoc, table_name, model_name, plural: false)
        assoc = plural ? table_name.to_sym : table_name.singularize.to_sym

        return if assoc == default_assoc

        params << "#{default_assoc}: :#{assoc}"
        params << "#{default_assoc.to_s.singularize}_class: '#{model_name}'" if model_name != assoc.to_s.classify
      end

      # Convert namespaced model names to proper table names
      # e.g., "Assistant::Chat" -> "assistant_chats" (not "assistant/chats")
      def table_name_for(model_name)
        model_name.underscore.pluralize.tr('/', '_')
      end

      # Convert model name to instance variable name
      # e.g., "LLM::Chat" -> "llm_chat" (not "llm/chat")
      def variable_name_for(model_name)
        model_name.underscore.tr('/', '_')
      end

      # Convert model name to controller class name
      # For namespaced models, use Rails convention: "Llm::Chat" -> "Llm::ChatsController"
      # For regular models: "Chat" -> "ChatsController"
      def controller_class_name_for(model_name)
        if model_name.include?('::')
          parts = model_name.split('::')
          namespace = parts[0..-2].join('::')
          resource = parts.last.pluralize
          "#{namespace}::#{resource}Controller"
        else
          "#{model_name.pluralize}Controller"
        end
      end

      # Convert model name to partial path
      # e.g., "LLM::Message" -> "llm/message" (not "llm_message")
      def partial_path_for(model_name)
        "#{model_name.underscore.pluralize}/#{model_name.demodulize.underscore}"
      end
    end
  end
end
