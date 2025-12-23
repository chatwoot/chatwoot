# frozen_string_literal: true

require 'rails/generators'
require_relative '../generator_helpers'

module RubyLLM
  module Generators
    # Generates a simple chat UI scaffold for RubyLLM
    class ChatUIGenerator < Rails::Generators::Base
      include RubyLLM::Generators::GeneratorHelpers

      source_root File.expand_path('templates', __dir__)

      namespace 'ruby_llm:chat_ui'

      argument :model_mappings, type: :array, default: [], banner: 'chat:ChatName message:MessageName ...'

      desc 'Creates a chat UI scaffold with Turbo streaming\n' \
           'Usage: rails g ruby_llm:chat_ui [chat:ChatName] [message:MessageName] ...'

      def check_model_exists
        model_path = "app/models/#{message_model_name.underscore}.rb"
        return if File.exist?(model_path)

        # Build the argument string for the install/upgrade commands
        args = []
        args << "chat:#{chat_model_name}" if chat_model_name != 'Chat'
        args << "message:#{message_model_name}" if message_model_name != 'Message'
        args << "model:#{model_model_name}" if model_model_name != 'Model'
        args << "tool_call:#{tool_call_model_name}" if tool_call_model_name != 'ToolCall'
        arg_string = args.any? ? " #{args.join(' ')}" : ''

        raise Thor::Error, <<~ERROR
          Model file not found: #{model_path}

          Please run the install generator first:
            rails generate ruby_llm:install#{arg_string}

          Or if upgrading from <= 1.6.x, run the upgrade generator:
            rails generate ruby_llm:upgrade_to_v1_7#{arg_string}
        ERROR
      end

      def create_views
        # For namespaced models, use the proper Rails convention path
        chat_view_path = chat_model_name.underscore.pluralize
        message_view_path = message_model_name.underscore.pluralize
        model_view_path = model_model_name.underscore.pluralize

        # Chat views
        template 'views/chats/index.html.erb', "app/views/#{chat_view_path}/index.html.erb"
        template 'views/chats/new.html.erb', "app/views/#{chat_view_path}/new.html.erb"
        template 'views/chats/show.html.erb', "app/views/#{chat_view_path}/show.html.erb"
        template 'views/chats/_chat.html.erb',
                 "app/views/#{chat_view_path}/_#{chat_model_name.demodulize.underscore}.html.erb"
        template 'views/chats/_form.html.erb', "app/views/#{chat_view_path}/_form.html.erb"

        # Message views
        template 'views/messages/_message.html.erb',
                 "app/views/#{message_view_path}/_#{message_model_name.demodulize.underscore}.html.erb"
        template 'views/messages/_tool_calls.html.erb',
                 "app/views/#{message_view_path}/_tool_calls.html.erb"
        template 'views/messages/_content.html.erb', "app/views/#{message_view_path}/_content.html.erb"
        template 'views/messages/_form.html.erb', "app/views/#{message_view_path}/_form.html.erb"
        template 'views/messages/create.turbo_stream.erb', "app/views/#{message_view_path}/create.turbo_stream.erb"

        # Model views
        template 'views/models/index.html.erb', "app/views/#{model_view_path}/index.html.erb"
        template 'views/models/show.html.erb', "app/views/#{model_view_path}/show.html.erb"
        template 'views/models/_model.html.erb',
                 "app/views/#{model_view_path}/_#{model_model_name.demodulize.underscore}.html.erb"
      end

      def create_controllers
        # For namespaced models, use the proper Rails convention path
        chat_controller_path = chat_model_name.underscore.pluralize
        message_controller_path = message_model_name.underscore.pluralize
        model_controller_path = model_model_name.underscore.pluralize

        template 'controllers/chats_controller.rb', "app/controllers/#{chat_controller_path}_controller.rb"
        template 'controllers/messages_controller.rb', "app/controllers/#{message_controller_path}_controller.rb"
        template 'controllers/models_controller.rb', "app/controllers/#{model_controller_path}_controller.rb"
      end

      def create_jobs
        template 'jobs/chat_response_job.rb', "app/jobs/#{variable_name_for(chat_model_name)}_response_job.rb"
      end

      def add_routes
        # For namespaced models, use Rails convention with namespace blocks
        if chat_model_name.include?('::')
          namespace = chat_model_name.deconstantize.underscore
          chat_resource = chat_model_name.demodulize.underscore.pluralize
          message_resource = message_model_name.demodulize.underscore.pluralize
          model_resource = model_model_name.demodulize.underscore.pluralize

          routes_content = <<~ROUTES.strip
            namespace :#{namespace} do
              resources :#{model_resource}, only: [:index, :show] do
                collection do
                  post :refresh
                end
              end
              resources :#{chat_resource} do
                resources :#{message_resource}, only: [:create]
              end
            end
          ROUTES
          route routes_content
        else
          model_routes = <<~ROUTES.strip
            resources :#{model_table_name}, only: [:index, :show] do
              collection do
                post :refresh
              end
            end
          ROUTES
          route model_routes
          chat_routes = <<~ROUTES.strip
            resources :#{chat_table_name} do
              resources :#{message_table_name}, only: [:create]
            end
          ROUTES
          route chat_routes
        end
      end

      def add_broadcasting_to_message_model
        msg_var = variable_name_for(message_model_name)
        chat_var = variable_name_for(chat_model_name)
        msg_path = message_model_name.underscore

        # For namespaced models, we need the association name which might be different
        # e.g., for LLM::Message, the chat association might be :llm_chat
        chat_association = chat_table_name.singularize

        # Use Rails convention paths for partials
        partial_path = message_model_name.underscore.pluralize

        # For broadcasts, we need to explicitly set the partial path
        # Turbo will pass the record with the demodulized name (e.g. 'message' for Llm::Message)
        broadcasting_code = if message_model_name.include?('::')
                              partial_name = "#{partial_path}/#{message_model_name.demodulize.underscore}"
                              <<~RUBY.strip
                                broadcasts_to ->(#{msg_var}) { "#{chat_var}_\#{#{msg_var}.#{chat_association}_id}" },
                                  partial: "#{partial_name}"
                              RUBY
                            else
                              "broadcasts_to ->(#{msg_var}) { \"#{chat_var}_\#{#{msg_var}.#{chat_association}_id}\" }"
                            end

        broadcast_append_chunk_method = <<-RUBY

  def broadcast_append_chunk(content)
    broadcast_append_to "#{chat_var}_\#{#{chat_association}_id}",
      target: "#{msg_var}_\#{id}_content",
      partial: "#{partial_path}/content",
      locals: { content: content }
  end
        RUBY

        inject_into_file "app/models/#{msg_path}.rb", before: "end\n" do
          "  #{broadcasting_code}\n#{broadcast_append_chunk_method}"
        end
      rescue Errno::ENOENT
        say "#{message_model_name} model not found. Add broadcasting code to your model.", :yellow
        say "  #{broadcasting_code}", :yellow
        say broadcast_append_chunk_method, :yellow
      end

      def display_post_install_message
        return unless behavior == :invoke

        # Show the correct URL based on whether models are namespaced
        url_path = if chat_model_name.include?('::')
                     chat_model_name.underscore.pluralize
                   else
                     chat_table_name
                   end

        say "\n  ✅ Chat UI installed!", :green
        say "\n  Start your server and visit http://localhost:3000/#{url_path}", :cyan
        say "\n"
      end
    end
  end
end
