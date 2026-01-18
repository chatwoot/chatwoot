# frozen_string_literal: true

class Api::V1::Accounts::Conversations::Messages::AttachmentsController < Api::V1::Accounts::Conversations::BaseController
  before_action :set_message
  before_action :set_attachment

  # POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:message_id/attachments/:id/retranscribe
  # Re-run transcription on an audio attachment
  def retranscribe
    unless @attachment.file_type == 'audio'
      return render json: { error: 'Only audio attachments can be retranscribed' }, status: :unprocessable_entity
    end

    assistant = @conversation.inbox.aloo_assistant
    unless assistant&.voice_transcription_enabled?
      return render json: { error: 'Voice transcription is not enabled for this assistant' }, status: :unprocessable_entity
    end

    # Reset transcription status
    meta = @attachment.meta || {}
    meta['transcription_status'] = 'pending'
    meta.delete('transcription_error')
    @attachment.update!(meta: meta)

    # Queue transcription job (don't trigger AI response)
    Aloo::AudioTranscriptionJob.perform_later(@attachment.id, trigger_response: false)

    render json: {
      status: 'queued',
      message: 'Transcription has been queued for processing',
      attachment_id: @attachment.id
    }
  end

  # GET /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:message_id/attachments/:id/transcription
  # Get transcription status and text for an attachment
  def transcription
    return render json: { error: 'Only audio attachments have transcriptions' }, status: :unprocessable_entity unless @attachment.file_type == 'audio'

    meta = @attachment.meta || {}

    render json: {
      attachment_id: @attachment.id,
      status: meta['transcription_status'] || 'none',
      transcribed_text: meta['transcribed_text'],
      error: meta['transcription_error'],
      updated_at: meta['transcription_updated_at']
    }
  end

  private

  def set_message
    @message = @conversation.messages.find(params[:message_id])
  end

  def set_attachment
    @attachment = @message.attachments.find(params[:id])
  end
end
