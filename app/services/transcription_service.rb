class TranscriptionService
  def self.transcribe_audio(attachment)
    Rails.logger.info "[TranscriptionService] Iniciando transcrição do attachment #{attachment.id}"

    return nil if ENV['GROQ_API_KEY'].blank?

    audio_file = download_audio(attachment)
    return nil unless audio_file

    transcribe_with_groq(audio_file, attachment)
  rescue StandardError => e
    Rails.logger.error "[TranscriptionService] Erro inesperado: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def self.download_audio(attachment)
    audio_url = attachment.download_url
    Rails.logger.info "[TranscriptionService] URL do áudio: #{audio_url}"

    Down.download(audio_url).tap do
      Rails.logger.info '[TranscriptionService] Arquivo de áudio baixado com sucesso'
    end
  rescue StandardError => e
    Rails.logger.error "[TranscriptionService] Erro ao baixar o arquivo de áudio: #{e.message}"
    nil
  end

  def self.transcribe_with_groq(audio_file, attachment)
    response = make_groq_request(audio_file)
    Rails.logger.info "[TranscriptionService] Resposta da API: #{response.code} - #{response.body}"

    if response.success?
      Rails.logger.info '[TranscriptionService] Transcrição concluída com sucesso'
      save_transcription(attachment, response.body)
      response.body
    else
      Rails.logger.error "[TranscriptionService] Erro na API: #{response.code} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "[TranscriptionService] Erro ao fazer requisição para a API: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def self.make_groq_request(audio_file)
    HTTParty.post(
      'https://api.groq.com/openai/v1/audio/transcriptions',
      headers: {
        'Authorization' => "Bearer #{ENV.fetch('GROQ_API_KEY')}",
        'Content-Type' => 'multipart/form-data'
      },
      body: {
        file: File.open(audio_file.path),
        model: 'whisper-large-v3-turbo',
        language: 'pt',
        response_format: 'text',
        temperature: 0
      }
    )
  end

  def self.save_transcription(attachment, transcription)
    attachment.transcription = transcription
    attachment.save!
  end
end
