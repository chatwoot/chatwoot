# frozen_string_literal: true

module Aloo
  class ResponseJob < ApplicationJob
    queue_as :default
    retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 3

    # Generate and send AI response for a conversation message
    # @param conversation_id [Integer] The conversation ID
    # @param message_id [Integer] The incoming message ID to respond to
    def perform(conversation_id, message_id)
      @conversation = Conversation.find_by(id: conversation_id)
      return unless @conversation

      @message = Message.find_by(id: message_id)
      return unless @message

      @inbox = @conversation.inbox
      @assistant = @inbox.aloo_assistant
      return unless @assistant&.active?

      # Don't respond if handoff is active
      return if handoff_active?

      # Don't respond to outgoing messages
      return unless @message.incoming?

      # Generate response
      response = generate_response

      # Send response if successful
      send_response(response) if response[:success] && response[:content].present?
    rescue StandardError => e
      Rails.logger.error("[Aloo::ResponseJob] Error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      raise # Re-raise to trigger retry
    end

    private

    def handoff_active?
      @conversation.custom_attributes&.dig('aloo_handoff_active') == true
    end

    def generate_response
      agent = ConversationAgent.new(
        account: @conversation.account,
        assistant: @assistant,
        conversation: @conversation,
        contact: @conversation.contact,
        message: @message
      )

      agent.call
    end

    def send_response(response)
      return if response[:skip_response]
      return if response[:handoff_triggered]

      # Create the outgoing message with assistant as sender
      Messages::MessageBuilder.new(
        @assistant,
        @conversation,
        {
          content: response[:content],
          message_type: :outgoing,
          private: false,
          content_attributes: build_content_attributes(response)
        }
      ).perform

      # Update conversation if needed
      update_conversation_status
    end

    def build_content_attributes(response)
      {
        'aloo_generated' => true,
        'aloo_assistant_id' => @assistant.id,
        'input_tokens' => response[:input_tokens],
        'output_tokens' => response[:output_tokens],
        'tool_calls' => response[:tool_calls]
      }
    end

    def update_conversation_status
      # Keep conversation open if it was pending
      return unless @conversation.pending?

      @conversation.update!(status: :open)
    end
  end
end
