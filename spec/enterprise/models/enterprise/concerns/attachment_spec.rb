require 'rails_helper'

RSpec.describe Attachment do
  describe 'audio transcription' do
    let(:conversation) { create(:conversation) }

    def build_audio_message
      message = conversation.messages.build(account: conversation.account, inbox: conversation.inbox,
                                            sender: conversation.contact, message_type: :incoming, content: nil)
      message.attachments.new(
        account_id: conversation.account_id,
        file_type: :audio,
        file: { io: Rails.root.join('spec/assets/sample.ogg').open, filename: 'voice.ogg', content_type: 'audio/ogg' }
      )
      message
    end

    it 'enqueues one transcription when the incoming message also updates the conversation' do
      # A blank waiting_since makes the incoming message update the conversation, which autosaves
      # the message and commits the attachment a second time.
      conversation.update!(waiting_since: nil)
      message = build_audio_message

      expect { message.save! }.to have_enqueued_job(Messages::AudioTranscriptionJob).once
    end
  end
end
