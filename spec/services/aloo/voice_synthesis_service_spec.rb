# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::VoiceSynthesisService, type: :service do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_voice_output, account: account) }
  let(:message) { create(:message, account: account) }
  let(:text) { 'Hello, this is a test message.' }
  let(:audio_binary) { 'fake-mp3-binary-data' }
  let(:ogg_path) { '/tmp/voice_output_123.ogg' }

  let(:speech_result) do
    instance_double(
      'SpeechResult',
      audio: audio_binary,
      error?: false,
      total_cost: 0.001,
      error_message: nil
    )
  end

  describe '#initialize' do
    it 'sets text, assistant, and optional message' do
      service = described_class.new(text: text, assistant: assistant, message: message)

      expect(service.text).to eq(text)
      expect(service.assistant).to eq(assistant)
      expect(service.message).to eq(message)
    end

    it 'accepts optional voice_id_override' do
      service = described_class.new(
        text: text,
        assistant: assistant,
        voice_id_override: 'custom-voice-id'
      )

      expect(service.voice_id_override).to eq('custom-voice-id')
    end
  end

  describe '#perform' do
    context 'when voice output is not enabled' do
      let(:assistant) { create(:aloo_assistant, account: account, voice_enabled: false) }

      it 'returns error result' do
        service = described_class.new(text: text, assistant: assistant)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Voice output not enabled')
      end
    end

    context 'when text is blank' do
      it 'returns error for empty string' do
        service = described_class.new(text: '', assistant: assistant)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Text is blank')
      end

      it 'returns error for nil text' do
        service = described_class.new(text: nil, assistant: assistant)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Text is blank')
      end
    end

    context 'when text is blank after sanitization' do
      it 'returns error for text with only URLs' do
        service = described_class.new(
          text: 'https://example.com https://test.com',
          assistant: assistant
        )
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Text is blank after sanitization')
      end
    end

    context 'with successful synthesis' do
      before do
        allow(Audio::AlooSpeaker).to receive(:call).and_return(speech_result)
        allow(Aloo::AudioConversionService).to receive(:convert_data_to_whatsapp).and_return(ogg_path)
      end

      it 'returns successful result with audio path' do
        service = described_class.new(text: text, assistant: assistant)
        result = service.perform

        expect(result[:success]).to be true
        expect(result[:audio_path]).to eq(ogg_path)
        expect(result[:audio_data]).to eq(audio_binary)
        expect(result[:content_type]).to eq('audio/ogg; codecs=opus')
        expect(result[:format]).to eq('ogg')
      end

      it 'calls AlooSpeaker with correct parameters' do
        service = described_class.new(text: text, assistant: assistant)

        expect(Audio::AlooSpeaker).to receive(:call).with(
          text: text,
          voice_id: assistant.elevenlabs_voice_id,
          model: assistant.effective_tts_model,
          voice_settings: hash_including(:stability, :similarity_boost),
          tenant: assistant.account
        ).and_return(speech_result)

        service.perform
      end

      it 'uses voice_id_override when provided' do
        service = described_class.new(
          text: text,
          assistant: assistant,
          voice_id_override: 'custom-voice-id'
        )

        expect(Audio::AlooSpeaker).to receive(:call).with(
          hash_including(voice_id: 'custom-voice-id')
        ).and_return(speech_result)

        service.perform
      end

      it 'converts audio to WhatsApp compatible format' do
        service = described_class.new(text: text, assistant: assistant)

        expect(Aloo::AudioConversionService).to receive(:convert_data_to_whatsapp).with(audio_binary)

        service.perform
      end

      it 'records voice usage' do
        service = described_class.new(text: text, assistant: assistant, message: message)

        expect do
          service.perform
        end.to change(Aloo::VoiceUsageRecord, :count).by(1)

        record = Aloo::VoiceUsageRecord.last
        expect(record.operation_type).to eq('synthesis')
        expect(record.status).to eq('success')
        expect(record.characters_used).to eq(text.length)
      end
    end

    context 'when speaker returns an error' do
      let(:error_result) do
        instance_double(
          'SpeechResult',
          error?: true,
          error_message: 'API quota exceeded'
        )
      end

      before do
        allow(Audio::AlooSpeaker).to receive(:call).and_return(error_result)
      end

      it 'returns error result' do
        service = described_class.new(text: text, assistant: assistant)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API quota exceeded')
      end

      it 'records failed usage' do
        service = described_class.new(text: text, assistant: assistant)

        expect do
          service.perform
        end.to change(Aloo::VoiceUsageRecord, :count).by(1)

        record = Aloo::VoiceUsageRecord.last
        expect(record.status).to eq('failed')
        expect(record.metadata['error']).to eq('API quota exceeded')
      end
    end

    context 'when provider raises RubyLLM::Error' do
      let(:ruby_llm_error) do
        response = double('Response', body: '{"error": "Connection refused"}')
        error = RubyLLM::Error.new(response)
        allow(error).to receive(:message).and_return('Connection refused')
        error
      end

      before do
        allow(Audio::AlooSpeaker).to receive(:call).and_raise(ruby_llm_error)
      end

      it 'returns error result' do
        service = described_class.new(text: text, assistant: assistant)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Connection refused')
      end
    end

    context 'when audio conversion fails' do
      before do
        allow(Audio::AlooSpeaker).to receive(:call).and_return(speech_result)
        allow(Aloo::AudioConversionService).to receive(:convert_data_to_whatsapp).and_raise(
          Aloo::AudioConversionService::ConversionError.new('FFmpeg not found')
        )
      end

      it 'returns error result' do
        service = described_class.new(text: text, assistant: assistant)
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('FFmpeg not found')
      end
    end
  end

  describe 'text sanitization' do
    before do
      allow(Audio::AlooSpeaker).to receive(:call).and_return(speech_result)
      allow(Aloo::AudioConversionService).to receive(:convert_data_to_whatsapp).and_return(ogg_path)
    end

    it 'removes markdown formatting' do
      markdown_text = '**Bold** and *italic* and `code`'

      expect(Audio::AlooSpeaker).to receive(:call).with(
        hash_including(text: 'Bold and italic and code')
      ).and_return(speech_result)

      described_class.new(text: markdown_text, assistant: assistant).perform
    end

    it 'removes URLs from text' do
      text_with_url = 'Visit https://example.com for more info'

      expect(Audio::AlooSpeaker).to receive(:call).with(
        hash_including(text: 'Visit for more info')
      ).and_return(speech_result)

      described_class.new(text: text_with_url, assistant: assistant).perform
    end

    it 'converts markdown links to text' do
      text_with_link = 'Click [here](https://example.com) for help'

      expect(Audio::AlooSpeaker).to receive(:call).with(
        hash_including(text: 'Click here for help')
      ).and_return(speech_result)

      described_class.new(text: text_with_link, assistant: assistant).perform
    end

    it 'normalizes whitespace' do
      text_with_spaces = "Hello   world\n\ntest"

      expect(Audio::AlooSpeaker).to receive(:call).with(
        hash_including(text: 'Hello world test')
      ).and_return(speech_result)

      described_class.new(text: text_with_spaces, assistant: assistant).perform
    end

    it 'truncates text exceeding max length' do
      long_text = 'a' * 6000

      expect(Audio::AlooSpeaker).to receive(:call) do |args|
        expect(args[:text].length).to be <= described_class::MAX_TEXT_LENGTH
        expect(args[:text]).to end_with('...')
        speech_result
      end

      described_class.new(text: long_text, assistant: assistant).perform
    end
  end

  describe 'voice settings' do
    before do
      allow(Audio::AlooSpeaker).to receive(:call).and_return(speech_result)
      allow(Aloo::AudioConversionService).to receive(:convert_data_to_whatsapp).and_return(ogg_path)
    end

    it 'uses assistant voice settings' do
      assistant.voice_config['elevenlabs_stability'] = 0.8
      assistant.voice_config['elevenlabs_similarity_boost'] = 0.9
      assistant.save!

      expect(Audio::AlooSpeaker).to receive(:call).with(
        hash_including(voice_settings: { stability: 0.8, similarity_boost: 0.9 })
      ).and_return(speech_result)

      described_class.new(text: text, assistant: assistant).perform
    end

    it 'uses default settings when not configured' do
      assistant.voice_config.delete('elevenlabs_stability')
      assistant.voice_config.delete('elevenlabs_similarity_boost')
      assistant.save!

      expect(Audio::AlooSpeaker).to receive(:call).with(
        hash_including(voice_settings: { stability: 0.5, similarity_boost: 0.75 })
      ).and_return(speech_result)

      described_class.new(text: text, assistant: assistant).perform
    end
  end
end
