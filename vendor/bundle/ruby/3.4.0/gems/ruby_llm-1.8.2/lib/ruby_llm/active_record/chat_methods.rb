# frozen_string_literal: true

module RubyLLM
  module ActiveRecord
    # Methods mixed into chat models.
    module ChatMethods
      extend ActiveSupport::Concern

      included do
        before_save :resolve_model_from_strings
      end

      attr_accessor :assume_model_exists, :context

      def model=(value)
        @model_string = value if value.is_a?(String)
        return if value.is_a?(String)

        if self.class.model_association_name == :model
          super
        else
          self.model_association = value
        end
      end

      def model_id=(value)
        @model_string = value
      end

      def model_id
        model_association&.model_id
      end

      def provider=(value)
        @provider_string = value
      end

      def provider
        model_association&.provider
      end

      private

      def resolve_model_from_strings # rubocop:disable Metrics/PerceivedComplexity
        config = context&.config || RubyLLM.config
        @model_string ||= config.default_model unless model_association
        return unless @model_string

        model_info, _provider = Models.resolve(
          @model_string,
          provider: @provider_string,
          assume_exists: assume_model_exists || false,
          config: config
        )

        model_class = self.class.model_class.constantize
        model_record = model_class.find_or_create_by!(
          model_id: model_info.id,
          provider: model_info.provider
        ) do |m|
          m.name = model_info.name || model_info.id
          m.family = model_info.family
          m.context_window = model_info.context_window
          m.max_output_tokens = model_info.max_output_tokens
          m.capabilities = model_info.capabilities || []
          m.modalities = model_info.modalities || {}
          m.pricing = model_info.pricing || {}
          m.metadata = model_info.metadata || {}
        end

        self.model_association = model_record
        @model_string = nil
        @provider_string = nil
      end

      public

      def to_llm
        model_record = model_association
        @chat ||= (context || RubyLLM).chat(
          model: model_record.model_id,
          provider: model_record.provider.to_sym
        )
        @chat.reset_messages!

        messages_association.each do |msg|
          @chat.add_message(msg.to_llm)
        end

        setup_persistence_callbacks
      end

      def with_instructions(instructions, replace: false)
        transaction do
          messages_association.where(role: :system).destroy_all if replace
          messages_association.create!(role: :system, content: instructions)
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

      def with_model(model_name, provider: nil, assume_exists: false)
        self.model = model_name
        self.provider = provider if provider
        self.assume_model_exists = assume_exists
        resolve_model_from_strings
        save!
        to_llm.with_model(model.model_id, provider: model.provider.to_sym, assume_exists:)
        self
      end

      def with_temperature(...)
        to_llm.with_temperature(...)
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
        message_record = messages_association.create!(role: :user, content: content)
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
        messages_association.reload
        last = messages_association.order(:id).last

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
        @message = messages_association.create!(role: :assistant, content: '')
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

          attrs = {
            role: message.role,
            content: content,
            input_tokens: message.input_tokens,
            output_tokens: message.output_tokens
          }

          # Add model association dynamically
          attrs[self.class.model_association_name] = model_association

          if tool_call_id
            parent_tool_call_assoc = @message.class.reflect_on_association(:parent_tool_call)
            attrs[parent_tool_call_assoc.foreign_key] = tool_call_id
          end

          @message.update!(attrs)

          persist_content(@message, attachments_to_persist) if attachments_to_persist
          persist_tool_calls(message.tool_calls) if message.tool_calls.present?
        end
      end

      def persist_tool_calls(tool_calls)
        tool_calls.each_value do |tool_call|
          attributes = tool_call.to_h
          attributes[:tool_call_id] = attributes.delete(:id)
          @message.tool_calls_association.create!(**attributes)
        end
      end

      def find_tool_call_id(tool_call_id)
        messages = messages_association
        message_class = messages.klass
        tool_calls_assoc = message_class.tool_calls_association_name
        tool_call_table_name = message_class.reflect_on_association(tool_calls_assoc).table_name

        message_with_tool_call = messages.joins(tool_calls_assoc)
                                         .find_by(tool_call_table_name => { tool_call_id: tool_call_id })
        return nil unless message_with_tool_call

        tool_call = message_with_tool_call.tool_calls_association.find_by(tool_call_id: tool_call_id)
        tool_call&.id
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
  end
end
