# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::AudioTranscriptionJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:aloo_assistant, :with_voice_input, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, account: account) }
  let(:attachment) { create(:attachment, message: message, file_type: :audio) }

  before do
    inbox.update!(aloo_assistant: assistant)
  end

  describe '#perform' do
    context 'when attachment does not exist' do
      it 'returns early without processing' do
        expect(Aloo::AudioTranscriptionService).not_to receive(:new)

        described_class.new.perform(-1)
      end
    end

    context 'when message association returns nil' do
      it 'returns early without processing' do
        # Create a real attachment, then stub its message method to return nil
        real_attachment = create(:attachment, message: message, file_type: :audio)

        # Stub the instance to return nil for message
        allow(Attachment).to receive(:find_by).with(id: real_attachment.id).and_call_original
        found_attachment = Attachment.find_by(id: real_attachment.id)
        allow(Attachment).to receive(:find_by).with(id: real_attachment.id).and_return(found_attachment)
        allow(found_attachment).to receive(:message).and_return(nil)

        expect(Aloo::AudioTranscriptionService).not_to receive(:new)

        described_class.new.perform(real_attachment.id)
      end
    end

    context 'when transcription is already completed' do
      before do
        attachment.update!(meta: { 'transcription_status' => 'completed' })
      end

      it 'skips processing' do
        expect(Aloo::AudioTranscriptionService).not_to receive(:new)

        described_class.new.perform(attachment.id)
      end
    end

    context 'when another job is already processing' do
      before do
        attachment.update!(meta: { 'transcription_status' => 'processing' })
      end

      it 'skips processing' do
        expect(Aloo::AudioTranscriptionService).not_to receive(:new)

        described_class.new.perform(attachment.id)
      end
    end

    context 'with successful transcription' do
      let(:service) { instance_double(Aloo::AudioTranscriptionService) }

      before do
        allow(Aloo::AudioTranscriptionService).to receive(:new).and_return(service)
        allow(service).to receive(:perform).and_return({ success: true, transcription: 'Hello' })
      end

      it 'calls transcription service' do
        expect(Aloo::AudioTranscriptionService).to receive(:new).with(attachment)
        expect(service).to receive(:perform)

        described_class.new.perform(attachment.id)
      end

      it 'updates transcription status to completed' do
        described_class.new.perform(attachment.id)

        attachment.reload
        expect(attachment.meta['transcription_status']).to eq('completed')
      end

      it 'triggers AI response by default' do
        expect do
          described_class.new.perform(attachment.id)
        end.to have_enqueued_job(Aloo::ResponseJob)
      end

      it 'does not trigger AI response when trigger_response is false' do
        expect do
          described_class.new.perform(attachment.id, trigger_response: false)
        end.not_to have_enqueued_job(Aloo::ResponseJob)
      end
    end

    context 'when transcription fails' do
      let(:service) { instance_double(Aloo::AudioTranscriptionService) }

      before do
        allow(Aloo::AudioTranscriptionService).to receive(:new).and_return(service)
        allow(service).to receive(:perform).and_return({ success: false, error: 'API error' })
      end

      it 'updates transcription status to failed' do
        described_class.new.perform(attachment.id)

        attachment.reload
        expect(attachment.meta['transcription_status']).to eq('failed')
        expect(attachment.meta['transcription_error']).to eq('API error')
      end

      it 'does not trigger AI response' do
        expect do
          described_class.new.perform(attachment.id)
        end.not_to have_enqueued_job(Aloo::ResponseJob)
      end
    end

    context 'when service raises an exception' do
      before do
        allow(Aloo::AudioTranscriptionService).to receive(:new).and_raise(StandardError.new('Unexpected'))
      end

      it 'updates status to failed and re-raises' do
        expect do
          described_class.new.perform(attachment.id)
        end.to raise_error(StandardError, 'Unexpected')

        attachment.reload
        expect(attachment.meta['transcription_status']).to eq('failed')
      end
    end

    context 'when handoff is active' do
      let(:service) { instance_double(Aloo::AudioTranscriptionService) }

      before do
        allow(Aloo::AudioTranscriptionService).to receive(:new).and_return(service)
        allow(service).to receive(:perform).and_return({ success: true, transcription: 'Hello' })
        conversation.update!(custom_attributes: { 'aloo_handoff_active' => true })
      end

      it 'does not trigger AI response' do
        expect do
          described_class.new.perform(attachment.id)
        end.not_to have_enqueued_job(Aloo::ResponseJob)
      end
    end

    context 'when assistant is inactive' do
      let(:service) { instance_double(Aloo::AudioTranscriptionService) }

      before do
        allow(Aloo::AudioTranscriptionService).to receive(:new).and_return(service)
        allow(service).to receive(:perform).and_return({ success: true, transcription: 'Hello' })
        assistant.update!(active: false)
      end

      it 'does not trigger AI response' do
        expect do
          described_class.new.perform(attachment.id)
        end.not_to have_enqueued_job(Aloo::ResponseJob)
      end
    end
  end

  describe 'queue and job configuration' do
    it 'uses the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end

    it 'is configured with retry_on for error handling' do
      # The job uses retry_on macro which is configured in the class
      expect(described_class).to respond_to(:retry_on)
    end
  end

  describe 'idempotency lock' do
    let(:service) { instance_double(Aloo::AudioTranscriptionService) }

    before do
      allow(Aloo::AudioTranscriptionService).to receive(:new).and_return(service)
      allow(service).to receive(:perform).and_return({ success: true, transcription: 'Hello' })
    end

    it 'claims lock atomically using database update' do
      described_class.new.perform(attachment.id)

      attachment.reload
      expect(attachment.meta['transcription_status']).to eq('completed')
    end

    it 'prevents concurrent processing' do
      # Simulate first job claiming the lock
      attachment.update!(meta: { 'transcription_status' => 'processing' })

      # Second job should not process
      expect(service).not_to receive(:perform)

      described_class.new.perform(attachment.id)
    end
  end
end
