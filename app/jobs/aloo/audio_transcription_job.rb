# frozen_string_literal: true

module Aloo
  class AudioTranscriptionJob < ApplicationJob
    queue_as :default
    retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 3
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(attachment_id, trigger_response: true)
      @attachment = Attachment.find_by(id: attachment_id)
      return unless @attachment

      @message = @attachment.message
      return unless @message

      # Idempotency: skip if already completed
      return if transcription_completed?

      # Claim lock to prevent concurrent processing
      return unless claim_transcription_lock

      begin
        update_status('processing')
        result = Aloo::AudioTranscriptionService.new(@attachment).perform

        if result[:success]
          update_status('completed')
          trigger_ai_response if trigger_response
        else
          update_status('failed', result[:error])
        end
      rescue StandardError => e
        update_status('failed', e.message)
        raise
      end
    end

    private

    def transcription_completed?
      @attachment.meta&.dig('transcription_status') == 'completed'
    end

    def claim_transcription_lock
      # Atomic update to prevent race conditions
      # Allow claiming if status is nil, 'pending', or 'failed' (for retries on transient errors)
      updated = Attachment
                .where(id: @attachment.id)
                .where(
                  "meta->>'transcription_status' IS NULL OR meta->>'transcription_status' IN ('pending', 'failed')"
                )
                .update_all(
                  "meta = jsonb_set(COALESCE(meta, '{}'), '{transcription_status}', '\"processing\"')"
                )

      updated.positive?
    end

    def update_status(status, error = nil)
      meta = @attachment.meta || {}
      meta['transcription_status'] = status
      meta['transcription_error'] = error if error
      meta['transcription_updated_at'] = Time.current.iso8601
      @attachment.update!(meta: meta)
    end

    def trigger_ai_response
      conversation = @message.conversation
      assistant = conversation.inbox.aloo_assistant

      return unless assistant&.active?
      return if conversation.assignee.present? && !conversation.assignee.try(:is_ai?)

      Aloo::ResponseJob.perform_later(conversation.id, @message.id)
    end
  end
end
