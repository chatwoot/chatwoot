# frozen_string_literal: true

module Aloo
  class AudioTranscriptionService
    MAX_FILE_SIZE = 25.megabytes

    attr_reader :attachment, :message, :assistant

    def initialize(attachment)
      @attachment = attachment
      @message = attachment.message
      @assistant = find_assistant
    end

    def perform
      return error_result('No assistant configured') unless assistant&.voice_transcription_enabled?
      return success_result(cached_transcription) if cached_transcription.present?
      return error_result('File too large for transcription') if file_too_large?

      transcribe_and_store
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::AudioTranscription] RubyLLM error: #{e.message}")
      error_result(e.message)
    rescue StandardError => e
      Rails.logger.error("[Aloo::AudioTranscription] Unexpected error: #{e.message}")
      error_result(e.message)
    end

    private

    def transcribe_and_store
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      temp_file = download_to_tempfile
      result = Audio::AlooTranscriber.call(
        audio: temp_file.path,
        language: language_hint,
        model: transcription_model,
        tenant: assistant.account
      )
      raise result.error_message if result.error?

      duration_seconds = result.audio_duration || estimate_duration(temp_file.path)
      transcription = result.text

      store_transcription(transcription)
      notify_message_updated

      log_success(transcription, duration_seconds, start_time)
      success_result(transcription)
    ensure
      temp_file&.close
      temp_file&.unlink
    end

    def download_to_tempfile
      extension = File.extname(attachment.file.filename.to_s)
      temp_file = Tempfile.new(['aloo_audio', extension], Rails.root.join('tmp'))
      temp_file.binmode

      if whatsapp_media_id.present?
        download_from_whatsapp(temp_file)
      else
        download_from_storage(temp_file)
      end

      temp_file.rewind
      temp_file
    end

    def download_from_whatsapp(temp_file)
      channel = message.inbox.channel
      phone_number_id = channel.provider_config['phone_number_id']

      # Step 1: Get the temporary download URL from WhatsApp media endpoint
      url_response = HTTParty.get(
        channel.media_url(whatsapp_media_id, phone_number_id),
        headers: channel.api_headers
      )
      raise "WhatsApp media API returned #{url_response.code}" unless url_response.success?

      # Step 2: Download the actual audio file from the temporary URL
      downloaded = Down.download(url_response.parsed_response['url'], headers: channel.api_headers)
      IO.copy_stream(downloaded, temp_file)
    rescue StandardError => e
      Rails.logger.warn("[Aloo::AudioTranscription] WhatsApp download failed (#{e.message}), falling back to S3")
      download_from_storage(temp_file)
    end

    def download_from_storage(temp_file)
      attachment.file.blob.open do |blob_file|
        IO.copy_stream(blob_file, temp_file)
      end
    end

    def whatsapp_media_id
      attachment.meta&.dig('whatsapp_media_id')
    end

    def transcription_model
      assistant.effective_transcription_model
    end

    def language_hint
      # Map assistant language to ISO 639-1 code
      case assistant.language
      when 'ar' then 'ar'
      when 'en' then 'en'
      else assistant.language
      end
    end

    def store_transcription(text)
      return if text.blank?

      meta = attachment.meta || {}
      meta['transcribed_text'] = text
      meta['transcription_status'] = 'completed'
      meta['transcription_updated_at'] = Time.current.iso8601
      attachment.update!(meta: meta)
    end

    def cached_transcription
      attachment.meta&.dig('transcribed_text')
    end

    def file_too_large?
      attachment.file.byte_size > MAX_FILE_SIZE
    end

    def find_assistant
      message&.inbox&.aloo_assistant
    end

    def notify_message_updated
      message.reload.send_update_event
    end

    def estimate_duration(file_path)
      # Rough estimate: 1MB ≈ 60 seconds for typical audio
      File.size(file_path) / (1024 * 1024) * 60
    rescue StandardError
      0
    end

    def log_success(transcription, duration_seconds, start_time)
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

      Rails.logger.info(
        '[Aloo::AudioTranscription] Completed: ' \
        "attachment_id=#{attachment.id} " \
        "duration=#{duration_seconds}s " \
        "chars=#{transcription.length} " \
        "model=#{transcription_model} " \
        "elapsed=#{elapsed_ms}ms"
      )
    end

    def success_result(transcription)
      { success: true, transcription: transcription }
    end

    def error_result(message)
      { success: false, error: message }
    end
  end
end
