# frozen_string_literal: true

module Aloo
  class VoiceSynthesisService
    MAX_TEXT_LENGTH = 5000
    TRUNCATION_SUFFIX = '...'

    attr_reader :text, :assistant, :message, :voice_id_override

    def initialize(text:, assistant:, message: nil, voice_id_override: nil)
      @text = text
      @assistant = assistant
      @message = message
      @voice_id_override = voice_id_override
    end

    def perform
      return error_result('Voice output not enabled') unless assistant.voice_reply_enabled?
      return error_result('Text is blank') if text.blank?

      sanitized_text = sanitize_text(text)
      return error_result('Text is blank after sanitization') if sanitized_text.blank?

      generate_voice(sanitized_text)
    rescue Aloo::ElevenlabsClient::Error => e
      Rails.logger.error("[Aloo::VoiceSynthesis] ElevenLabs error: #{e.message}")
      record_usage(success: false, error: e.message)
      error_result(e.message)
    rescue Aloo::AudioConversionService::ConversionError => e
      Rails.logger.error("[Aloo::VoiceSynthesis] Conversion error: #{e.message}")
      record_usage(success: false, error: e.message)
      error_result(e.message)
    rescue StandardError => e
      Rails.logger.error("[Aloo::VoiceSynthesis] Unexpected error: #{e.message}")
      record_usage(success: false, error: e.message)
      error_result(e.message)
    end

    private

    def generate_voice(sanitized_text)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Generate MP3 from ElevenLabs
      client = Aloo::ElevenlabsClient.new
      audio_data = client.text_to_speech(
        text: sanitized_text,
        voice_id: effective_voice_id,
        model_id: assistant.effective_tts_model,
        voice_settings: voice_settings
      )

      # Convert to OGG for WhatsApp compatibility
      ogg_path = Aloo::AudioConversionService.convert_data_to_whatsapp(audio_data)

      # Record usage
      record_usage(success: true, characters: sanitized_text.length)

      log_success(sanitized_text, start_time)

      success_result(ogg_path, audio_data)
    end

    def effective_voice_id
      voice_id_override.presence || assistant.elevenlabs_voice_id
    end

    def voice_settings
      {
        stability: assistant.elevenlabs_stability&.to_f || 0.5,
        similarity_boost: assistant.elevenlabs_similarity_boost&.to_f || 0.75
      }
    end

    def sanitize_text(input)
      result = input.to_s.dup

      # Remove markdown formatting
      result.gsub!(/[*_~`#]/, '')
      result.gsub!(/\[([^\]]+)\]\([^)]+\)/, '\1') # [link](url) → link

      # Replace URLs with placeholder
      result.gsub!(%r{https?://\S+}, '')

      # Normalize whitespace
      result = result.gsub(/\s+/, ' ').strip

      # Truncate if too long
      result = result[0...(MAX_TEXT_LENGTH - TRUNCATION_SUFFIX.length)] + TRUNCATION_SUFFIX if result.length > MAX_TEXT_LENGTH

      result
    end

    def record_usage(success:, characters: 0, error: nil)
      return unless assistant

      Aloo::VoiceUsageRecord.record_synthesis(
        account: assistant.account,
        assistant: assistant,
        message: message,
        characters: characters,
        voice_id: effective_voice_id,
        model: assistant.effective_tts_model,
        success: success,
        error: error
      )
    end

    def log_success(text, start_time)
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

      Rails.logger.info(
        '[Aloo::VoiceSynthesis] Completed: ' \
        "assistant_id=#{assistant.id} " \
        "chars=#{text.length} " \
        "voice_id=#{effective_voice_id} " \
        "elapsed=#{elapsed_ms}ms"
      )
    end

    def success_result(ogg_path, mp3_data)
      {
        success: true,
        audio_path: ogg_path,
        audio_data: mp3_data,
        content_type: 'audio/ogg; codecs=opus',
        format: 'ogg'
      }
    end

    def error_result(message)
      { success: false, error: message }
    end
  end
end
