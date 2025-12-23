# frozen_string_literal: true

module RubyLLM
  module ActiveRecord
    # Adds chat and message persistence capabilities to ActiveRecord models.
    module ActsAsLegacy
      extend ActiveSupport::Concern

      class_methods do # rubocop:disable Metrics/BlockLength
        def acts_as_chat(message_class: 'Message', tool_call_class: 'ToolCall')
          include ChatLegacyMethods

          @message_class = message_class.to_s
          @tool_call_class = tool_call_class.to_s

          has_many :messages,
                   -> { order(created_at: :asc) },
                   class_name: @message_class,
                   inverse_of: :chat,
                   dependent: :destroy

          delegate :add_message, to: :to_llm
        end

        def acts_as_message(chat_class: 'Chat',
                            chat_foreign_key: nil,
                            tool_call_class: 'ToolCall',
                            tool_call_foreign_key: nil,
                            touch_chat: false)
          include MessageLegacyMethods

          @chat_class = chat_class.to_s
          @chat_foreign_key = chat_foreign_key || ActiveSupport::Inflector.foreign_key(@chat_class)

          @tool_call_class = tool_call_class.to_s
          @tool_call_foreign_key = tool_call_foreign_key || ActiveSupport::Inflector.foreign_key(@tool_call_class)

          belongs_to :chat,
                     class_name: @chat_class,
                     foreign_key: @chat_foreign_key,
                     inverse_of: :messages,
                     touch: touch_chat

          has_many :tool_calls,
                   class_name: @tool_call_class,
                   dependent: :destroy

          belongs_to :parent_tool_call,
                     class_name: @tool_call_class,
                     foreign_key: @tool_call_foreign_key,
                     optional: true,
                     inverse_of: :result

          has_many :tool_results,
                   through: :tool_calls,
                   source: :result,
                   class_name: @message_class

          delegate :tool_call?, :tool_result?, to: :to_llm
        end

        def acts_as_tool_call(message_class: 'Message', message_foreign_key: nil, result_foreign_key: nil)
          @message_class = message_class.to_s
          @message_foreign_key = message_foreign_key || ActiveSupport::Inflector.foreign_key(@message_class)
          @result_foreign_key = result_foreign_key || ActiveSupport::Inflector.foreign_key(name)

          belongs_to :message,
                     class_name: @message_class,
                     foreign_key: @message_foreign_key,
                     inverse_of: :tool_calls

          has_one :result,
                  class_name: @message_class,
                  foreign_key: @result_foreign_key,
                  inverse_of: :parent_tool_call,
                  dependent: :nullify
        end
      end
    end

    # Methods mixed into chat models.
    module ChatLegacyMethods
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :tool_call_class
      end

      def to_llm(context: nil)
        # model_id is a string that RubyLLM can resolve
        @chat ||= if context
                    context.chat(model: model_id)
                  else
                    RubyLLM.chat(model: model_id)
                  end
        @chat.reset_messages!

        messages.each do |msg|
          @chat.add_message(msg.to_llm)
        end

        setup_persistence_callbacks
      end

      def with_instructions(instructions, replace: false)
        transaction do
          messages.where(role: :system).destroy_all if replace
          messages.create!(role: :system, content: instructions)
        end
        to_llm.with_instructions(instructions)
        self
      end

      def with_tool(...)
        to_llm.with_tool(...)
        self
      end

      def with_tools(...)
        to_llm.with_tools(...)
        self
      end

      def with_model(...)
        update(model_id: to_llm.with_model(...).model.id)
        self
      end

      def with_temperature(...)
        to_llm.with_temperature(...)
        self
      end

      def with_context(context)
        to_llm(context: context)
        self
      end

      def with_params(...)
        to_llm.with_params(...)
        self
      end

      def with_headers(...)
        to_llm.with_headers(...)
        self
      end

      def with_schema(...)
        to_llm.with_schema(...)
        self
      end

      def on_new_message(&block)
        to_llm

        existing_callback = @chat.instance_variable_get(:@on)[:new_message]

        @chat.on_new_message do
          existing_callback&.call
          block&.call
        end
        self
      end

      def on_end_message(&block)
        to_llm

        existing_callback = @chat.instance_variable_get(:@on)[:end_message]

        @chat.on_end_message do |msg|
          existing_callback&.call(msg)
          block&.call(msg)
        end
        self
      end

      def on_tool_call(...)
        to_llm.on_tool_call(...)
        self
      end

      def on_tool_result(...)
        to_llm.on_tool_result(...)
        self
      end

      def create_user_message(content, with: nil)
        message_record = messages.create!(role: :user, content: content)
        persist_content(message_record, with) if with.present?
        message_record
      end

      def ask(message, with: nil, &)
        create_user_message(message, with:)
        complete(&)
      end

      alias say ask

      def complete(...)
        to_llm.complete(...)
      rescue RubyLLM::Error => e
        cleanup_failed_messages if @message&.persisted? && @message.content.blank?
        cleanup_orphaned_tool_results
        raise e
      end

      private

      def cleanup_failed_messages
        RubyLLM.logger.warn "RubyLLM: API call failed, destroying message: #{@message.id}"
        @message.destroy
      end

      def cleanup_orphaned_tool_results # rubocop:disable Metrics/PerceivedComplexity
        messages.reload
        last = messages.order(:id).last

        return unless last&.tool_call? || last&.tool_result?

        if last.tool_call?
          last.destroy
        elsif last.tool_result?
          tool_call_message = last.parent_tool_call.message
          expected_results = tool_call_message.tool_calls.pluck(:id)
          actual_results = tool_call_message.tool_results.pluck(:tool_call_id)

          if expected_results.sort != actual_results.sort
            tool_call_message.tool_results.each(&:destroy)
            tool_call_message.destroy
          end
        end
      end

      def setup_persistence_callbacks
        return @chat if @chat.instance_variable_get(:@_persistence_callbacks_setup)

        @chat.on_new_message { persist_new_message }
        @chat.on_end_message { |msg| persist_message_completion(msg) }

        @chat.instance_variable_set(:@_persistence_callbacks_setup, true)
        @chat
      end

      def persist_new_message
        @message = messages.create!(role: :assistant, content: '')
      end

      def persist_message_completion(message) # rubocop:disable Metrics/PerceivedComplexity
        return unless message

        tool_call_id = find_tool_call_id(message.tool_call_id) if message.tool_call_id

        transaction do
          content = message.content
          attachments_to_persist = nil

          if content.is_a?(RubyLLM::Content)
            attachments_to_persist = content.attachments if content.attachments.any?
            content = content.text
          elsif content.is_a?(Hash) || content.is_a?(Array)
            content = content.to_json
          end

          @message.update!(
            role: message.role,
            content: content,
            model_id: message.model_id,
            input_tokens: message.input_tokens,
            output_tokens: message.output_tokens
          )
          @message.write_attribute(@message.class.tool_call_foreign_key, tool_call_id) if tool_call_id
          @message.save!

          persist_content(@message, attachments_to_persist) if attachments_to_persist
          persist_tool_calls(message.tool_calls) if message.tool_calls.present?
        end
      end

      def persist_tool_calls(tool_calls)
        tool_calls.each_value do |tool_call|
          attributes = tool_call.to_h
          attributes[:tool_call_id] = attributes.delete(:id)
          @message.tool_calls.create!(**attributes)
        end
      end

      def find_tool_call_id(tool_call_id)
        self.class.tool_call_class.constantize.find_by(tool_call_id: tool_call_id)&.id
      end

      def persist_content(message_record, attachments)
        return unless message_record.respond_to?(:attachments)

        attachables = prepare_for_active_storage(attachments)
        message_record.attachments.attach(attachables) if attachables.any?
      end

      def prepare_for_active_storage(attachments)
        Utils.to_safe_array(attachments).filter_map do |attachment|
          case attachment
          when ActionDispatch::Http::UploadedFile, ActiveStorage::Blob
            attachment
          when ActiveStorage::Attached::One, ActiveStorage::Attached::Many
            attachment.blobs
          when Hash
            attachment.values.map { |v| prepare_for_active_storage(v) }
          else
            convert_to_active_storage_format(attachment)
          end
        end.flatten.compact
      end

      def convert_to_active_storage_format(source)
        return if source.blank?

        attachment = source.is_a?(RubyLLM::Attachment) ? source : RubyLLM::Attachment.new(source)

        {
          io: StringIO.new(attachment.content),
          filename: attachment.filename,
          content_type: attachment.mime_type
        }
      rescue StandardError => e
        RubyLLM.logger.warn "Failed to process attachment #{source}: #{e.message}"
        nil
      end
    end

    # Methods mixed into message models.
    module MessageLegacyMethods
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :chat_class, :tool_call_class, :chat_foreign_key, :tool_call_foreign_key
      end

      def to_llm
        RubyLLM::Message.new(
          role: role.to_sym,
          content: extract_content,
          tool_calls: extract_tool_calls,
          tool_call_id: extract_tool_call_id,
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          model_id: model_id
        )
      end

      private

      def extract_tool_calls
        tool_calls.to_h do |tool_call|
          [
            tool_call.tool_call_id,
            RubyLLM::ToolCall.new(
              id: tool_call.tool_call_id,
              name: tool_call.name,
              arguments: tool_call.arguments
            )
          ]
        end
      end

      def extract_tool_call_id
        parent_tool_call&.tool_call_id
      end

      def extract_content
        return content unless respond_to?(:attachments) && attachments.attached?

        RubyLLM::Content.new(content).tap do |content_obj|
          @_tempfiles = []

          attachments.each do |attachment|
            tempfile = download_attachment(attachment)
            content_obj.add_attachment(tempfile, filename: attachment.filename.to_s)
          end
        end
      end

      def download_attachment(attachment)
        ext = File.extname(attachment.filename.to_s)
        basename = File.basename(attachment.filename.to_s, ext)
        tempfile = Tempfile.new([basename, ext])
        tempfile.binmode

        attachment.download { |chunk| tempfile.write(chunk) }

        tempfile.flush
        tempfile.rewind
        @_tempfiles << tempfile
        tempfile
      end
    end
  end
end
