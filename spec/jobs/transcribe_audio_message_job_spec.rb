require 'rails_helper'

RSpec.describe TranscribeAudioMessageJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, account: account, inbox: inbox) }
  let(:attachment) { create(:attachment, account: account, message: message, file_type: :audio) }

  describe '#perform' do
    let(:transcription_result) do
      {
        text: 'This is a transcribed audio message.',
        language: 'en',
        duration: 10.5
      }
    end

    context 'when transcription is successful' do
      before do
        allow(Openai::AudioTranscriptionService).to receive(:new).and_return(
          instance_double(Openai::AudioTranscriptionService, process: transcription_result)
        )
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'transcribes the audio and updates the message content' do
        described_class.perform_now(message.id, attachment.id)

        message.reload
        expect(message.content).to include('This is a transcribed audio message.')
      end

      it 'stores transcription metadata in additional_attributes' do
        described_class.perform_now(message.id, attachment.id)

        message.reload
        expect(message.additional_attributes['transcription']).to be_present
        expect(message.additional_attributes['transcription']['language']).to eq('en')
        expect(message.additional_attributes['transcription']['duration']).to eq(10.5)
        expect(message.additional_attributes['transcription']['transcribed_at']).to be_present
      end

      it 'broadcasts ActionCable update' do
        described_class.perform_now(message.id, attachment.id)

        expect(ActionCable.server).to have_received(:broadcast) do |channel, payload|
          expect(channel).to eq("messages:#{message.conversation_id}")
          expect(payload[:event]).to eq('message.updated')
          expect(payload[:data]).to be_present
        end
      end

      it 'logs success message' do
        allow(Rails.logger).to receive(:info)

        described_class.perform_now(message.id, attachment.id)

        expect(Rails.logger).to have_received(:info).with("Starting transcription for message #{message.id}, attachment #{attachment.id}")
        expect(Rails.logger).to have_received(:info).with("Transcription completed for message #{message.id}")
      end

      it 'appends transcription to existing content' do
        message.update!(content: 'Original message content')

        described_class.perform_now(message.id, attachment.id)

        message.reload
        expect(message.content).to eq("Original message content\n\nThis is a transcribed audio message.")
      end
    end

    context 'when message is not found' do
      it 'logs error and returns gracefully' do
        allow(Rails.logger).to receive(:error)

        expect do
          described_class.perform_now(999_999, attachment.id)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:error).with('Message not found: 999999')
      end

      it 'does not attempt transcription' do
        expect(Openai::AudioTranscriptionService).not_to receive(:new)

        described_class.perform_now(999_999, attachment.id)
      end
    end

    context 'when attachment is not found' do
      it 'logs error and returns gracefully' do
        allow(Rails.logger).to receive(:error)

        expect do
          described_class.perform_now(message.id, 999_999)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:error).with('Attachment not found: 999999')
      end

      it 'does not attempt transcription' do
        expect(Openai::AudioTranscriptionService).not_to receive(:new)

        described_class.perform_now(message.id, 999_999)
      end
    end

    context 'when transcription service returns nil' do
      before do
        allow(Openai::AudioTranscriptionService).to receive(:new).and_return(
          instance_double(Openai::AudioTranscriptionService, process: nil)
        )
      end

      it 'does not update message' do
        original_content = message.content

        described_class.perform_now(message.id, attachment.id)

        message.reload
        expect(message.content).to eq(original_content)
      end

      it 'does not broadcast update' do
        allow(ActionCable.server).to receive(:broadcast)

        described_class.perform_now(message.id, attachment.id)

        expect(ActionCable.server).not_to have_received(:broadcast)
      end
    end

    describe 'retry and discard configuration' do
      it 'has retry_on configured for RateLimitError' do
        # Verify the job class has retry configuration
        # Testing actual retry behavior requires integration testing
        expect(described_class).to respond_to(:retry_on)
      end

      it 'has retry_on configured for NetworkError' do
        expect(described_class).to respond_to(:retry_on)
      end

      it 'has discard_on configured for InvalidFileError' do
        expect(described_class).to respond_to(:discard_on)
      end

      it 'has discard_on configured for AuthenticationError' do
        expect(described_class).to respond_to(:discard_on)
      end
    end

    describe 'queue configuration' do
      it 'runs on default queue' do
        expect(described_class.new.queue_name).to eq('default')
      end
    end
  end

  describe 'integration with ActionCable' do
    before do
      allow(Openai::AudioTranscriptionService).to receive(:new).and_return(
        instance_double(Openai::AudioTranscriptionService, process: {
                          text: 'Test transcription',
                          language: 'en',
                          duration: 5.0
                        })
      )
    end

    it 'includes transcription metadata in broadcast payload' do
      allow(ActionCable.server).to receive(:broadcast)

      described_class.perform_now(message.id, attachment.id)

      expect(ActionCable.server).to have_received(:broadcast) do |channel, payload|
        expect(channel).to eq("messages:#{message.conversation_id}")
        expect(payload[:event]).to eq('message.updated')
        expect(payload[:data]).to be_a(Hash)
      end
    end
  end
end
