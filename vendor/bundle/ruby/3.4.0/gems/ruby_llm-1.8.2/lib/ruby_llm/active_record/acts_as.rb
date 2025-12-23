# frozen_string_literal: true

module RubyLLM
  module ActiveRecord
    # Adds chat and message persistence capabilities to ActiveRecord models.
    module ActsAs
      extend ActiveSupport::Concern

      # When ActsAs is included, ensure models are loaded from database
      def self.included(base)
        super
        # Monkey-patch Models to use database when ActsAs is active
        RubyLLM::Models.class_eval do
          def load_models
            read_from_database
          rescue StandardError => e
            RubyLLM.logger.debug "Failed to load models from database: #{e.message}, falling back to JSON"
            read_from_json
          end

          def load_from_database!
            @models = read_from_database
          end

          def read_from_database
            model_class = RubyLLM.config.model_registry_class
            model_class = model_class.constantize if model_class.is_a?(String)
            model_class.all.map(&:to_llm)
          end
        end
      end

      class_methods do # rubocop:disable Metrics/BlockLength
        def acts_as_chat(messages: :messages, message_class: nil,
                         model: :model, model_class: nil)
          include RubyLLM::ActiveRecord::ChatMethods

          class_attribute :messages_association_name, :model_association_name, :message_class, :model_class

          self.messages_association_name = messages
          self.model_association_name = model
          self.message_class = (message_class || messages.to_s.classify).to_s
          self.model_class = (model_class || model.to_s.classify).to_s

          has_many messages,
                   -> { order(created_at: :asc) },
                   class_name: self.message_class,
                   foreign_key: ActiveSupport::Inflector.foreign_key(table_name.singularize),
                   dependent: :destroy

          belongs_to model,
                     class_name: self.model_class,
                     foreign_key: ActiveSupport::Inflector.foreign_key(model.to_s.singularize),
                     optional: true

          delegate :add_message, to: :to_llm

          define_method :messages_association do
            send(messages_association_name)
          end

          define_method :model_association do
            send(model_association_name)
          end

          define_method :'model_association=' do |value|
            send("#{model_association_name}=", value)
          end
        end

        def acts_as_model(chats: :chats, chat_class: nil)
          include RubyLLM::ActiveRecord::ModelMethods

          class_attribute :chats_association_name, :chat_class

          self.chats_association_name = chats
          self.chat_class = (chat_class || chats.to_s.classify).to_s

          validates :model_id, presence: true, uniqueness: { scope: :provider }
          validates :provider, presence: true
          validates :name, presence: true

          has_many chats,
                   class_name: self.chat_class,
                   foreign_key: ActiveSupport::Inflector.foreign_key(table_name.singularize)

          define_method :chats_association do
            send(chats_association_name)
          end
        end

        def acts_as_message(chat: :chat, chat_class: nil, touch_chat: false, # rubocop:disable Metrics/ParameterLists
                            tool_calls: :tool_calls, tool_call_class: nil,
                            model: :model, model_class: nil)
          include RubyLLM::ActiveRecord::MessageMethods

          class_attribute :chat_association_name, :tool_calls_association_name, :model_association_name,
                          :chat_class, :tool_call_class, :model_class

          self.chat_association_name = chat
          self.tool_calls_association_name = tool_calls
          self.model_association_name = model
          self.chat_class = (chat_class || chat.to_s.classify).to_s
          self.tool_call_class = (tool_call_class || tool_calls.to_s.classify).to_s
          self.model_class = (model_class || model.to_s.classify).to_s

          belongs_to chat,
                     class_name: self.chat_class,
                     foreign_key: ActiveSupport::Inflector.foreign_key(chat.to_s.singularize),
                     touch: touch_chat

          has_many tool_calls,
                   class_name: self.tool_call_class,
                   foreign_key: ActiveSupport::Inflector.foreign_key(table_name.singularize),
                   dependent: :destroy

          belongs_to :parent_tool_call,
                     class_name: self.tool_call_class,
                     foreign_key: ActiveSupport::Inflector.foreign_key(tool_calls.to_s.singularize),
                     optional: true

          has_many :tool_results,
                   through: tool_calls,
                   source: :result,
                   class_name: name

          belongs_to model,
                     class_name: self.model_class,
                     foreign_key: ActiveSupport::Inflector.foreign_key(model.to_s.singularize),
                     optional: true

          delegate :tool_call?, :tool_result?, to: :to_llm

          define_method :chat_association do
            send(chat_association_name)
          end

          define_method :tool_calls_association do
            send(tool_calls_association_name)
          end

          define_method :model_association do
            send(model_association_name)
          end
        end

        def acts_as_tool_call(message: :message, message_class: nil,
                              result: :result, result_class: nil)
          class_attribute :message_association_name, :result_association_name, :message_class, :result_class

          self.message_association_name = message
          self.result_association_name = result
          self.message_class = (message_class || message.to_s.classify).to_s
          self.result_class = (result_class || self.message_class).to_s

          belongs_to message,
                     class_name: self.message_class,
                     foreign_key: ActiveSupport::Inflector.foreign_key(message.to_s.singularize)

          has_one result,
                  class_name: self.result_class,
                  foreign_key: ActiveSupport::Inflector.foreign_key(table_name.singularize),
                  dependent: :nullify

          define_method :message_association do
            send(message_association_name)
          end

          define_method :result_association do
            send(result_association_name)
          end
        end
      end
    end
  end
end
