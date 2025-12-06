require 'rails_helper'

describe AudioTranscriptionListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let(:event_name) { 'message.created' }

  describe '#message_created' do
    context 'when message has audio attachments' do
      let!(:message) { create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation) }
      let!(:audio_attachment) { create_audio_attachment(message) }
      let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

      context 'when OpenAI integration is enabled with audio_transcription' do
        let!(:openai_hook) do
          create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled',
                                     settings: { 'api_key' => 'test-api-key', 'audio_transcription' => true })
        end

        it 'enqueues transcription job' do
          job_double = double
          expect(TranscribeAudioMessageJob).to receive(:set).with(wait: 2.seconds).and_return(job_double)
          expect(job_double).to receive(:perform_later).with(message.id, audio_attachment.id)
          listener.message_created(event)
        end
      end

      context 'when OpenAI integration exists but audio_transcription is disabled' do
        let!(:openai_hook) do
          create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled',
                                     settings: { 'api_key' => 'test-api-key', 'audio_transcription' => false })
        end

        it 'does not enqueue transcription job' do
          expect(TranscribeAudioMessageJob).not_to receive(:set)
          listener.message_created(event)
        end
      end

      context 'when OpenAI integration exists but audio_transcription is not set' do
        let!(:openai_hook) do
          create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled',
                                     settings: { 'api_key' => 'test-api-key' })
        end

        it 'does not enqueue transcription job' do
          expect(TranscribeAudioMessageJob).not_to receive(:set)
          listener.message_created(event)
        end
      end

      context 'when OpenAI integration is disabled' do
        let!(:openai_hook) do
          create(:integrations_hook, account: account, app_id: 'openai', status: 'disabled',
                                     settings: { 'api_key' => 'test-api-key', 'audio_transcription' => true })
        end

        it 'does not enqueue transcription job' do
          expect(TranscribeAudioMessageJob).not_to receive(:set)
          listener.message_created(event)
        end
      end

      context 'when OpenAI integration has empty API key' do
        let!(:openai_hook) do
          create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled',
                                     settings: { 'api_key' => '', 'audio_transcription' => true })
        end

        it 'does not enqueue transcription job' do
          expect(TranscribeAudioMessageJob).not_to receive(:set)
          listener.message_created(event)
        end
      end

      context 'when no OpenAI integration exists' do
        it 'does not enqueue transcription job' do
          expect(TranscribeAudioMessageJob).not_to receive(:set)
          listener.message_created(event)
        end
      end
    end

    context 'when message has multiple audio attachments' do
      let!(:message) { create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation) }
      let!(:audio_attachment1) { create_audio_attachment(message) }
      let!(:audio_attachment2) { create_audio_attachment(message) }
      let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }
      let!(:openai_hook) do
        create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled',
                                   settings: { 'api_key' => 'test-api-key', 'audio_transcription' => true })
      end

      it 'enqueues transcription job for each audio attachment' do
        job_double1 = double
        job_double2 = double
        expect(TranscribeAudioMessageJob).to receive(:set).with(wait: 2.seconds).and_return(job_double1)
        expect(job_double1).to receive(:perform_later).with(message.id, audio_attachment1.id)
        expect(TranscribeAudioMessageJob).to receive(:set).with(wait: 2.seconds).and_return(job_double2)
        expect(job_double2).to receive(:perform_later).with(message.id, audio_attachment2.id)
        listener.message_created(event)
      end
    end

    context 'when message has no audio attachments' do
      let!(:message) { create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation) }
      let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }
      let!(:openai_hook) do
        create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled',
                                   settings: { 'api_key' => 'test-api-key', 'audio_transcription' => true })
      end

      it 'does not enqueue transcription job' do
        expect(TranscribeAudioMessageJob).not_to receive(:perform_later)
        listener.message_created(event)
      end
    end

    context 'when message has mixed attachment types' do
      let!(:message) { create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation) }
      let!(:audio_attachment) { create_audio_attachment(message) }
      let!(:image_attachment) { create_image_attachment(message) }
      let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }
      let!(:openai_hook) do
        create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled',
                                   settings: { 'api_key' => 'test-api-key', 'audio_transcription' => true })
      end

      it 'only enqueues transcription job for audio attachments' do
        job_double = double
        expect(TranscribeAudioMessageJob).to receive(:set).with(wait: 2.seconds).and_return(job_double)
        expect(job_double).to receive(:perform_later).with(message.id, audio_attachment.id)
        listener.message_created(event)
      end
    end

    context 'when integration check raises an error' do
      let!(:message) { create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation) }
      let!(:audio_attachment) { create_audio_attachment(message) }
      let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

      before do
        allow(account).to receive(:hooks).and_raise(StandardError.new('Database error'))
      end

      it 'handles the error gracefully and does not enqueue job' do
        expect(Rails.logger).to receive(:error).with(/Error checking transcription settings/)
        expect(TranscribeAudioMessageJob).not_to receive(:perform_later)
        listener.message_created(event)
      end
    end
  end

  private

  def create_audio_attachment(message)
    attachment = message.attachments.build(
      account_id: message.account_id,
      file_type: :audio
    )
    attachment.file.attach(
      io: File.open(Rails.root.join('spec/assets/sample.mp3')),
      filename: 'sample.mp3',
      content_type: 'audio/mpeg'
    )
    attachment.save!
    attachment
  end

  def create_image_attachment(message)
    attachment = message.attachments.build(
      account_id: message.account_id,
      file_type: :image
    )
    attachment.file.attach(
      io: File.open(Rails.root.join('spec/assets/avatar.png')),
      filename: 'avatar.png',
      content_type: 'image/png'
    )
    attachment.save!
    attachment
  end
end
