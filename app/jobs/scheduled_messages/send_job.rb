# frozen_string_literal: true

module ScheduledMessages
  class SendJob < ApplicationJob
    queue_as :high

    def perform(scheduled_message_id)
      scheduled_message = ScheduledMessage.find(scheduled_message_id)

      # Verifica se ainda está pendente e na hora
      return unless scheduled_message.pending?
      return if scheduled_message.scheduled_at > Time.current

      ActiveRecord::Base.transaction do
        # Cria mensagem real usando MessageBuilder
        message = create_message(scheduled_message)

        # Atualiza scheduled_message
        scheduled_message.mark_as_sent!(message)

        Rails.logger.info "ScheduledMessage #{scheduled_message.id} sent as Message #{message.id}"
      end
    rescue StandardError => e
      scheduled_message.mark_as_failed!(e.message)
      Rails.logger.error "Failed to send ScheduledMessage #{scheduled_message.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end

    private

    def create_message(scheduled_message)
      # Usa MessageBuilder para criar a mensagem
      mb = Messages::MessageBuilder.new(
        scheduled_message.sender,
        scheduled_message.conversation,
        message_params(scheduled_message)
      )
      message = mb.perform

      # SendReplyJob já é chamado automaticamente no after_create_commit do Message
      message
    end

    def message_params(scheduled_message)
      {
        content: scheduled_message.content,
        message_type: scheduled_message.message_type,
        content_type: scheduled_message.content_type,
        private: scheduled_message.private,
        content_attributes: scheduled_message.content_attributes,
        additional_attributes: scheduled_message.additional_attributes
      }.with_indifferent_access
    end
  end
end
