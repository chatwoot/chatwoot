# frozen_string_literal: true

module Aloo
  class ResponseJob < ApplicationJob
    queue_as :default
    retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 3

    MAX_CONVERSATION_HISTORY = 20

    def perform(conversation_id, message_id)
      @conversation = Conversation.find_by(id: conversation_id)
      return unless @conversation

      @message = Message.find_by(id: message_id)
      return unless @message

      @inbox = @conversation.inbox
      @assistant = @inbox.aloo_assistant
      return unless @assistant&.active?

      return if handoff_active?
      return unless @message.incoming?

      set_aloo_context do
        result = generate_response
        send_response(result) if result.success? && result.content.present?
      end
    rescue StandardError => e
      Rails.logger.error("[Aloo::ResponseJob] Error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      raise
    end

    private

    def handoff_active?
      @conversation.custom_attributes&.dig('aloo_handoff_active') == true
    end

    def set_aloo_context
      Aloo::Current.account = @conversation.account
      Aloo::Current.assistant = @assistant
      Aloo::Current.conversation = @conversation
      Aloo::Current.contact = @conversation.contact
      Aloo::Current.inbox = @inbox
      Aloo::Current.request_id = SecureRandom.uuid
      yield
    ensure
      Aloo::Current.reset
    end

    def generate_response
      conversation_history = build_conversation_history

      ConversationAgent.call(
        message: @message.content,
        conversation_history: conversation_history
      )
    end

    def build_conversation_history
      recent_messages = @conversation.messages
                                     .where(message_type: %i[incoming outgoing])
                                     .where(private: false)
                                     .order(created_at: :desc)
                                     .limit(MAX_CONVERSATION_HISTORY)
                                     .reverse

      return '' if recent_messages.empty?

      history = recent_messages.map do |msg|
        role = msg.message_type == 'incoming' ? 'Customer' : 'Assistant'
        "#{role}: #{msg.content}"
      end

      "## Conversation History\n#{history.join("\n\n")}"
    end

    def send_response(result)
      return if check_handoff_triggered(result)

      Messages::MessageBuilder.new(
        @assistant,
        @conversation,
        {
          content: result.content,
          message_type: :outgoing,
          private: false,
          content_attributes: build_content_attributes(result)
        }
      ).perform

      track_usage(result)
      update_conversation_status
    end

    def check_handoff_triggered(result)
      return false unless result.respond_to?(:tool_calls) && result.tool_calls

      result.tool_calls.any? { |tc| tc.name == 'handoff' }
    end

    def build_content_attributes(result)
      {
        'aloo_generated' => true,
        'aloo_assistant_id' => @assistant.id,
        'input_tokens' => result.input_tokens,
        'output_tokens' => result.output_tokens,
        'tool_calls' => result.tool_calls&.map(&:name)
      }
    end

    def track_usage(result)
      context = Aloo::ConversationContext.find_or_create_by!(
        conversation: @conversation,
        assistant: @assistant
      ) do |ctx|
        ctx.context_data = {}
        ctx.tool_history = []
      end

      context.track_message!(
        input_tokens: result.input_tokens || 0,
        output_tokens: result.output_tokens || 0,
        cost: estimate_cost(result)
      )
    end

    def estimate_cost(result)
      return 0 unless result.input_tokens && result.output_tokens

      input_cost = result.input_tokens * 0.00015 / 1000
      output_cost = result.output_tokens * 0.0006 / 1000
      input_cost + output_cost
    end

    def update_conversation_status
      return unless @conversation.pending?

      @conversation.update!(status: :open)
    end
  end
end
