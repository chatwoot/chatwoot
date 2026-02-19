# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::AudioTranscriptionService, type: :service do
  let(:account) { create(:account) }
  let(:temp_file) { Tempfile.new(['test_audio', '.mp3']) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:aloo_assistant, :with_voice_input, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, account: account) }
  let(:attachment) do
    # Create attachment without file validation
    att = Attachment.new(
      message: message,
      account: account,
      file_type: :audio
    )
    att.save!(validate: false)
    att
  end

  # Helper to stub file properties when needed
  def stub_attachment_file(att, byte_size: 1.megabyte)
    file_double = double('ActiveStorage::Attached::One')
    allow(file_double).to receive(:byte_size).and_return(byte_size)
    allow(file_double).to receive(:filename).and_return(OpenStruct.new(to_s: 'audio.mp3'))
    allow(file_double).to receive(:attached?).and_return(true)
    allow(file_double).to receive(:content_type).and_return('audio/mpeg')
    allow(att).to receive(:file).and_return(file_double)
  end

  before do
    inbox.update!(aloo_assistant: assistant)
  end

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '#initialize' do
    it 'sets the attachment, message, and assistant' do
      service = described_class.new(attachment)

      expect(service.attachment).to eq(attachment)
      expect(service.message).to eq(message)
      expect(service.assistant).to eq(assistant)
    end
  end

  describe '#perform' do
    context 'when assistant is not configured' do
      before do
        inbox.update!(aloo_assistant: nil)
      end

      it 'returns error result' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('No assistant configured')
      end
    end

    context 'when voice transcription is not enabled' do
      before do
        assistant.update!(voice_enabled: false)
      end

      it 'returns error result' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('No assistant configured')
      end
    end

    context 'when transcription is already cached' do
      before do
        attachment.update!(meta: { 'transcribed_text' => 'Cached transcription text' })
      end

      it 'returns cached transcription without calling transcriber' do
        service = described_class.new(attachment)

        expect(Audio::AlooTranscriber).not_to receive(:call)

        result = service.perform

        expect(result[:success]).to be true
        expect(result[:transcription]).to eq('Cached transcription text')
      end
    end

    context 'when file is too large' do
      before do
        stub_attachment_file(attachment, byte_size: 30.megabytes)
      end

      it 'returns error result' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('File too large for transcription')
      end
    end

    context 'with successful transcription' do
      let(:transcription_result) do
        instance_double(
          'TranscriptionResult',
          text: 'Hello, this is a test',
          audio_duration: 15.0,
          error?: false,
          total_cost: 0.0015,
          error_message: nil
        )
      end

      before do
        stub_attachment_file(attachment)
        allow_any_instance_of(described_class).to receive(:download_to_tempfile).and_return(temp_file)
        allow(Audio::AlooTranscriber).to receive(:call).and_return(transcription_result)
        allow(message).to receive(:send_update_event)
      end

      it 'returns successful result with transcription' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:success]).to be true
        expect(result[:transcription]).to eq('Hello, this is a test')
      end

      it 'stores transcription in attachment meta' do
        service = described_class.new(attachment)
        service.perform

        attachment.reload
        expect(attachment.meta['transcribed_text']).to eq('Hello, this is a test')
        expect(attachment.meta['transcription_status']).to eq('completed')
      end

      it 'returns the transcription text' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:transcription]).to eq('Hello, this is a test')
      end

      it 'calls AlooTranscriber with correct parameters' do
        service = described_class.new(attachment)

        expect(Audio::AlooTranscriber).to receive(:call).with(
          audio: anything,
          language: 'en',
          model: 'whisper-1',
          tenant: assistant.account
        ).and_return(transcription_result)

        service.perform
      end

      it 'notifies message update' do
        service = described_class.new(attachment)

        expect(message).to receive(:send_update_event)

        service.perform
      end
    end

    context 'when transcriber returns an error result' do
      let(:error_result) do
        instance_double(
          'TranscriptionResult',
          error?: true,
          error_message: 'API error'
        )
      end

      before do
        stub_attachment_file(attachment)
        allow_any_instance_of(described_class).to receive(:download_to_tempfile).and_return(temp_file)
        allow(Audio::AlooTranscriber).to receive(:call).and_return(error_result)
      end

      it 'returns error result' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API error')
      end

      it 'does not raise an error' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:success]).to be false
      end
    end

    context 'when RubyLLM raises an error' do
      let(:ruby_llm_error) do
        response = double('Response', body: '{"error": "API error"}')
        error = RubyLLM::Error.new(response)
        allow(error).to receive(:message).and_return('API error')
        error
      end

      before do
        stub_attachment_file(attachment)
        allow_any_instance_of(described_class).to receive(:download_to_tempfile).and_return(temp_file)
        allow(Audio::AlooTranscriber).to receive(:call).and_raise(ruby_llm_error)
      end

      it 'returns error result' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API error')
      end
    end

    context 'when an unexpected error occurs' do
      before do
        stub_attachment_file(attachment)
        allow_any_instance_of(described_class).to receive(:download_to_tempfile).and_return(temp_file)
        allow(Audio::AlooTranscriber).to receive(:call).and_raise(StandardError.new('Unexpected error'))
      end

      it 'returns error result' do
        service = described_class.new(attachment)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Unexpected error')
      end

      it 'logs the error' do
        service = described_class.new(attachment)

        expect(Rails.logger).to receive(:error).with(/Unexpected error/)

        service.perform
      end
    end
  end

  describe 'telegram download path' do
    let(:telegram_channel) { create(:channel_telegram) }
    let(:telegram_inbox) { telegram_channel.inbox }
    let(:telegram_assistant) { create(:aloo_assistant, :with_voice_input, account: telegram_channel.account) }
    let(:telegram_conversation) { create(:conversation, account: telegram_channel.account, inbox: telegram_inbox) }
    let(:telegram_message) { create(:message, conversation: telegram_conversation, account: telegram_channel.account) }
    let(:telegram_file_id) { 'AwACAgUAAxkBAANjYVwnWF_test_file_id' }
    let(:telegram_attachment) do
      att = telegram_message.attachments.new(
        account: telegram_channel.account,
        file_type: :audio,
        meta: { 'telegram_file_id' => telegram_file_id }
      )
      att.file.attach(io: File.open(Rails.root.join('spec/assets/sample.ogg')), filename: 'voice.ogg', content_type: 'audio/ogg')
      att.save!
      att
    end

    before do
      create(:aloo_assistant_inbox, assistant: telegram_assistant, inbox: telegram_inbox)

      stub_request(:get, 'https://api.telegram.org/bot2324234324/getFile')
        .with(query: { 'file_id' => telegram_file_id })
        .to_return(
          status: 200,
          headers: { 'content-type' => 'application/json' },
          body: { 'ok' => true, 'result' => { 'file_path' => 'voice/test.ogg' } }.to_json
        )
      stub_request(:get, 'https://api.telegram.org/file/bot2324234324/voice/test.ogg')
        .to_return(status: 200, body: File.read(Rails.root.join('spec/assets/sample.ogg')),
                   headers: { 'content-type' => 'audio/ogg' })
    end

    it 'downloads from Telegram API when telegram_file_id is present' do
      service = described_class.new(telegram_attachment)
      temp_file = service.send(:download_to_tempfile)

      expect(temp_file.size).to be > 0
      assert_requested(:get, 'https://api.telegram.org/bot2324234324/getFile',
                       query: { 'file_id' => telegram_file_id })
      assert_requested(:get, 'https://api.telegram.org/file/bot2324234324/voice/test.ogg')

      temp_file.close
      temp_file.unlink
    end

    context 'when Telegram API fails' do
      before do
        stub_request(:get, 'https://api.telegram.org/bot2324234324/getFile')
          .with(query: { 'file_id' => telegram_file_id })
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'falls back to storage download' do
        service = described_class.new(telegram_attachment)
        temp_file = service.send(:download_to_tempfile)

        expect(temp_file.size).to be > 0

        temp_file.close
        temp_file.unlink
      end
    end
  end

  describe 'language hint' do
    context 'when assistant is configured for Arabic' do
      let(:assistant) { create(:aloo_assistant, :with_voice_input, :arabic, account: account) }
      let(:transcription_result) do
        instance_double(
          'TranscriptionResult',
          text: 'مرحبا',
          audio_duration: 5.0,
          error?: false,
          total_cost: 0.0005,
          error_message: nil
        )
      end

      before do
        stub_attachment_file(attachment)
        allow_any_instance_of(described_class).to receive(:download_to_tempfile).and_return(temp_file)
        allow(Audio::AlooTranscriber).to receive(:call).and_return(transcription_result)
        allow(message).to receive(:send_update_event)
      end

      it 'passes Arabic language hint to transcriber' do
        service = described_class.new(attachment)

        expect(Audio::AlooTranscriber).to receive(:call).with(
          hash_including(language: 'ar')
        ).and_return(transcription_result)

        service.perform
      end
    end
  end
end
