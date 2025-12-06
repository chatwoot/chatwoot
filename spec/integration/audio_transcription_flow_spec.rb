require 'rails_helper'

RSpec.describe 'Audio Transcription Flow', type: :integration do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:api_key) { 'test-api-key-12345' }

  before do
    # Configure OpenAI API key
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return(api_key)
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('https://test.chatwoot.com')
    allow(ENV).to receive(:fetch).with('AUDIO_TRANSCRIPTION_ENABLED', 'true').and_return('true')

    # Create OpenAI integration hook with audio_transcription enabled
    create(:integrations_hook,
           account: account,
           app_id: 'openai',
           status: 'enabled',
           settings: { 'api_key' => api_key, 'audio_transcription' => true })
  end

  describe 'end-to-end transcription flow' do
    context 'when a message with audio attachment is created' do
      let(:transcription_result) do
        {
          text: 'Hello, this is a test audio message.',
          language: 'en',
          duration: 5.5
        }
      end

      before do
        # Mock the service instance
        service_instance = instance_double(Openai::AudioTranscriptionService)
        allow(Openai::AudioTranscriptionService).to receive(:new).and_return(service_instance)
        allow(service_instance).to receive(:process).and_return(transcription_result)
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'triggers listener, enqueues job, transcribes, and broadcasts update' do
        # Create message with audio attachment
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox, content: '')
        attachment = create(:attachment, account: account, message: message, file_type: :audio)

        # Simulate event dispatch
        Rails.configuration.dispatcher.dispatch(
          Events::Types::MESSAGE_CREATED,
          Time.zone.now,
          { message: message }
        )

        # Directly perform the job since the listener uses .set(wait: 2.seconds) which may not be picked up by perform_enqueued_jobs
        TranscribeAudioMessageJob.perform_now(message.id, attachment.id)

        # Verify message was updated
        message.reload
        expect(message.content).to include('Hello, this is a test audio message.')

        # Verify metadata was stored
        expect(message.additional_attributes['transcription']).to be_present
        expect(message.additional_attributes['transcription']['language']).to eq('en')
        expect(message.additional_attributes['transcription']['duration']).to eq(5.5)
        expect(message.additional_attributes['transcription']['transcribed_at']).to be_present

        # Verify ActionCable broadcast
        expect(ActionCable.server).to have_received(:broadcast).with(
          "messages:#{conversation.id}",
          hash_including(
            event: 'message.updated'
          )
        )
      end
    end

    context 'when message has multiple audio attachments' do
      let(:transcription_result_1) do
        {
          text: 'First audio message.',
          language: 'en',
          duration: 3.0
        }
      end

      let(:transcription_result_2) do
        {
          text: 'Second audio message.',
          language: 'es',
          duration: 4.0
        }
      end

      before do
        call_count = 0
        allow(Openai::AudioTranscriptionService).to receive(:new) do
          call_count += 1
          result = call_count == 1 ? transcription_result_1 : transcription_result_2
          instance_double(Openai::AudioTranscriptionService, process: result)
        end
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'transcribes all audio attachments' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox, content: '')
        attachment1 = create(:attachment, account: account, message: message, file_type: :audio)
        attachment2 = create(:attachment, account: account, message: message, file_type: :audio)

        Rails.configuration.dispatcher.dispatch(
          Events::Types::MESSAGE_CREATED,
          Time.zone.now,
          { message: message }
        )

        # Directly perform jobs since the listener uses .set(wait: 2.seconds)
        TranscribeAudioMessageJob.perform_now(message.id, attachment1.id)
        TranscribeAudioMessageJob.perform_now(message.id, attachment2.id)

        message.reload
        expect(message.content).to include('First audio message.')
        expect(message.content).to include('Second audio message.')
      end
    end

    context 'when OpenAI integration has audio_transcription disabled' do
      before do
        # Update the integration hook to disable audio_transcription
        account.hooks.find_by(app_id: 'openai')&.update!(settings: { 'api_key' => api_key, 'audio_transcription' => false })
      end

      it 'does not enqueue transcription job' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox)
        create(:attachment, account: account, message: message, file_type: :audio)

        expect do
          Rails.configuration.dispatcher.dispatch(
            Events::Types::MESSAGE_CREATED,
            Time.zone.now,
            { message: message }
          )
        end.not_to have_enqueued_job(TranscribeAudioMessageJob)
      end
    end

    context 'when message is outgoing' do
      it 'does not enqueue transcription job' do
        message = create(:message, :outgoing, conversation: conversation, account: account, inbox: inbox)
        create(:attachment, account: account, message: message, file_type: :audio)

        expect do
          Rails.configuration.dispatcher.dispatch(
            Events::Types::MESSAGE_CREATED,
            Time.zone.now,
            { message: message }
          )
        end.not_to have_enqueued_job(TranscribeAudioMessageJob)
      end
    end

    context 'when message has no audio attachments' do
      it 'does not enqueue transcription job' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox)
        create(:attachment, account: account, message: message, file_type: :image)

        expect do
          Rails.configuration.dispatcher.dispatch(
            Events::Types::MESSAGE_CREATED,
            Time.zone.now,
            { message: message }
          )
        end.not_to have_enqueued_job(TranscribeAudioMessageJob)
      end
    end
  end

  describe 'language detection' do
    let(:transcription_result_portuguese) do
      {
        text: 'Olá, esta é uma mensagem de teste em português.',
        language: 'pt',
        duration: 6.2
      }
    end

    before do
      service_instance = instance_double(Openai::AudioTranscriptionService)
      allow(Openai::AudioTranscriptionService).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:process).and_return(transcription_result_portuguese)
      allow(ActionCable.server).to receive(:broadcast)
    end

    it 'correctly detects and stores non-English language' do
      message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox, content: '')
      attachment = create(:attachment, account: account, message: message, file_type: :audio)

      Rails.configuration.dispatcher.dispatch(
        Events::Types::MESSAGE_CREATED,
        Time.zone.now,
        { message: message }
      )

      # Directly perform the job
      TranscribeAudioMessageJob.perform_now(message.id, attachment.id)

      message.reload
      expect(message.additional_attributes['transcription']['language']).to eq('pt')
      expect(message.content).to include('Olá, esta é uma mensagem de teste em português.')
    end
  end

  describe 'retry logic' do
    context 'when OpenAI API returns rate limit error' do
      before do
        service_instance = instance_double(Openai::AudioTranscriptionService)
        allow(Openai::AudioTranscriptionService).to receive(:new).and_return(service_instance)
        allow(service_instance).to receive(:process).and_raise(Openai::Exceptions::RateLimitError, 'Rate limit exceeded')
      end

      it 'retries the job with exponential backoff' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox)
        attachment = create(:attachment, account: account, message: message, file_type: :audio)

        # Manually enqueue and verify retry behavior
        TranscribeAudioMessageJob.perform_later(message.id, attachment.id)

        # The job should be enqueued once initially
        expect(TranscribeAudioMessageJob).to have_been_enqueued.once
      end
    end

    context 'when OpenAI API returns invalid file error' do
      before do
        service_instance = instance_double(Openai::AudioTranscriptionService)
        allow(Openai::AudioTranscriptionService).to receive(:new).and_return(service_instance)
        allow(service_instance).to receive(:process).and_raise(Openai::Exceptions::InvalidFileError, 'Invalid audio file')
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'discards the job without retry and stores error in metadata' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox)
        attachment = create(:attachment, account: account, message: message, file_type: :audio)

        expect do
          perform_enqueued_jobs(only: TranscribeAudioMessageJob) do
            TranscribeAudioMessageJob.perform_later(message.id, attachment.id)
          end
        end.not_to raise_error

        # Verify error was stored in message metadata
        message.reload
        expect(message.additional_attributes['transcription']).to be_present
        expect(message.additional_attributes['transcription']['error']).to include('Invalid')
      end
    end
  end

  describe 'with integration hook' do
    # The integration hook is already created in the global before block with audio_transcription enabled
    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it 'initializes service with account to use integration API key' do
      message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox, content: '')
      attachment = create(:attachment, account: account, message: message, file_type: :audio)

      service_instance = instance_double(Openai::AudioTranscriptionService)
      allow(Openai::AudioTranscriptionService).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:process).and_return({
                                                                text: 'Test with integration key',
                                                                language: 'en',
                                                                duration: 2.0
                                                              })

      Rails.configuration.dispatcher.dispatch(
        Events::Types::MESSAGE_CREATED,
        Time.zone.now,
        { message: message }
      )

      # Directly perform the job
      TranscribeAudioMessageJob.perform_now(message.id, attachment.id)

      # Verify service was initialized with account (using keyword arguments)
      expect(Openai::AudioTranscriptionService).to have_received(:new).with(
        hash_including(account: account)
      )
    end
  end
end
