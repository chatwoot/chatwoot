require 'rails_helper'

RSpec.describe 'Audio Transcription Flow', type: :integration do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:api_key) { 'test-api-key-12345' }

  before do
    # Configure OpenAI API key
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return(api_key)
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('https://test.chatwoot.com')
    allow(ENV).to receive(:fetch).with('AUDIO_TRANSCRIPTION_ENABLED', 'true').and_return('true')

    # Mock file download
    tempfile = instance_double(Tempfile, path: '/tmp/audio.ogg', close: true, unlink: true)
    allow(Down).to receive(:download).and_return(tempfile)
  end

  describe 'end-to-end transcription flow' do
    context 'when a message with audio attachment is created' do
      let(:transcription_response) do
        {
          'text' => 'Hello, this is a test audio message.',
          'language' => 'en',
          'duration' => 5.5
        }
      end

      before do
        # Mock OpenAI API response
        allow(Openai::AudioTranscriptionService).to receive(:post).and_return(
          double(success?: true, parsed_response: transcription_response)
        )
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'triggers listener, enqueues job, transcribes, and broadcasts update' do
        # Create message with audio attachment
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox, content: '')
        create(:attachment, account: account, message: message, file_type: :audio)

        # Simulate event dispatch
        Rails.configuration.dispatcher.publish_event(
          MESSAGE_CREATED,
          Time.zone.now,
          { message: message }
        )

        # Process enqueued jobs
        perform_enqueued_jobs do
          # The listener should have enqueued the job
        end

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
      let(:transcription_response_1) do
        {
          'text' => 'First audio message.',
          'language' => 'en',
          'duration' => 3.0
        }
      end

      let(:transcription_response_2) do
        {
          'text' => 'Second audio message.',
          'language' => 'es',
          'duration' => 4.0
        }
      end

      before do
        call_count = 0
        allow(Openai::AudioTranscriptionService).to receive(:post) do
          call_count += 1
          response = call_count == 1 ? transcription_response_1 : transcription_response_2
          double(success?: true, parsed_response: response)
        end
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'transcribes all audio attachments' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox, content: '')
        create(:attachment, account: account, message: message, file_type: :audio)
        create(:attachment, account: account, message: message, file_type: :audio)

        Rails.configuration.dispatcher.publish_event(
          MESSAGE_CREATED,
          Time.zone.now,
          { message: message }
        )

        perform_enqueued_jobs

        message.reload
        expect(message.content).to include('First audio message.')
        expect(message.content).to include('Second audio message.')
      end
    end

    context 'when OpenAI API is not configured' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return(nil)
      end

      it 'does not enqueue transcription job' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox)
        create(:attachment, account: account, message: message, file_type: :audio)

        expect do
          Rails.configuration.dispatcher.publish_event(
            MESSAGE_CREATED,
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
          Rails.configuration.dispatcher.publish_event(
            MESSAGE_CREATED,
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
          Rails.configuration.dispatcher.publish_event(
            MESSAGE_CREATED,
            Time.zone.now,
            { message: message }
          )
        end.not_to have_enqueued_job(TranscribeAudioMessageJob)
      end
    end
  end

  describe 'language detection' do
    let(:transcription_response_portuguese) do
      {
        'text' => 'Olá, esta é uma mensagem de teste em português.',
        'language' => 'pt',
        'duration' => 6.2
      }
    end

    before do
      allow(Openai::AudioTranscriptionService).to receive(:post).and_return(
        double(success?: true, parsed_response: transcription_response_portuguese)
      )
      allow(ActionCable.server).to receive(:broadcast)
    end

    it 'correctly detects and stores non-English language' do
      message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox, content: '')
      create(:attachment, account: account, message: message, file_type: :audio)

      Rails.configuration.dispatcher.publish_event(
        MESSAGE_CREATED,
        Time.zone.now,
        { message: message }
      )

      perform_enqueued_jobs

      message.reload
      expect(message.additional_attributes['transcription']['language']).to eq('pt')
      expect(message.content).to include('Olá, esta é uma mensagem de teste em português.')
    end
  end

  describe 'retry logic' do
    context 'when OpenAI API returns rate limit error' do
      before do
        allow(Openai::AudioTranscriptionService).to receive(:post).and_return(
          double(success?: false, code: 429, body: 'Rate limit exceeded')
        )
      end

      it 'retries the job with exponential backoff' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox)
        attachment = create(:attachment, account: account, message: message, file_type: :audio)

        expect do
          perform_enqueued_jobs do
            TranscribeAudioMessageJob.perform_later(message.id, attachment.id)
          end
        end.to raise_error(Openai::Exceptions::RateLimitError)

        # Job should be scheduled for retry
        expect(TranscribeAudioMessageJob).to have_been_enqueued.exactly(3).times
      end
    end

    context 'when OpenAI API returns invalid file error' do
      before do
        allow(Openai::AudioTranscriptionService).to receive(:post).and_return(
          double(success?: false, code: 400, body: 'Invalid audio file')
        )
        allow(Rails.logger).to receive(:error)
      end

      it 'discards the job without retry' do
        message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox)
        attachment = create(:attachment, account: account, message: message, file_type: :audio)

        expect do
          perform_enqueued_jobs(only: TranscribeAudioMessageJob) do
            TranscribeAudioMessageJob.perform_later(message.id, attachment.id)
          end
        end.not_to raise_error

        # Job should not be retried
        expect(TranscribeAudioMessageJob).to have_been_enqueued.once
      end
    end
  end

  describe 'with integration hook' do
    let(:integration_api_key) { 'integration-api-key-xyz' }

    before do
      create(:integrations_hook,
             account: account,
             app_id: 'openai',
             status: 'enabled',
             settings: { 'api_key' => integration_api_key })

      allow(Openai::AudioTranscriptionService).to receive(:post).and_return(
        double(success?: true, parsed_response: {
                 'text' => 'Test with integration key',
                 'language' => 'en',
                 'duration' => 2.0
               })
      )
      allow(ActionCable.server).to receive(:broadcast)
    end

    it 'uses integration API key instead of environment variable' do
      message = create(:message, :incoming, conversation: conversation, account: account, inbox: inbox, content: '')
      create(:attachment, account: account, message: message, file_type: :audio)

      service_instance = instance_double(Openai::AudioTranscriptionService)
      allow(Openai::AudioTranscriptionService).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:process).and_return({
                                                                text: 'Test with integration key',
                                                                language: 'en',
                                                                duration: 2.0
                                                              })

      Rails.configuration.dispatcher.publish_event(
        MESSAGE_CREATED,
        Time.zone.now,
        { message: message }
      )

      perform_enqueued_jobs

      # Verify service was initialized with account
      expect(Openai::AudioTranscriptionService).to have_received(:new).with(
        anything,
        hash_including(account: account)
      )
    end
  end
end
