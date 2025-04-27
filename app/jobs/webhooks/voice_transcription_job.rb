module Webhooks
  # This job handles voice transcriptions from Twilio when a voice channel is configured
  class VoiceTranscriptionJob < ApplicationJob
    queue_as :default

    def perform(params)
      call_sid = params['CallSid']
      transcription_text = params['TranscriptionText']
      
      return if call_sid.blank? || transcription_text.blank?
      
      # Find the conversation based on the call_sid stored in message metadata
      message = Message.find_by('additional_attributes @> ?', { call_sid: call_sid }.to_json)
      return if message.blank?
      
      conversation = message.conversation
      
      Message.create!(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        conversation_id: conversation.id,
        message_type: :incoming,
        content: transcription_text,
        sender: conversation.contact
      )
    end
  end
end