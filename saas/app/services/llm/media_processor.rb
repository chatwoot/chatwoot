# frozen_string_literal: true

# Processes media attachments (audio, image, document) for AI agent consumption.
# - Audio: transcribes via Whisper (OpenAI) and caches in attachment.meta['transcribed_text']
# - Image: describes via GPT-4 vision and returns description text
# - Document: extracts text content for context
#
# Usage:
#   processor = Llm::MediaProcessor.new
#   text = processor.process_attachment(attachment)
#   # => "Transcrição do áudio: Olá, gostaria de saber sobre..."
#
class Llm::MediaProcessor
  VISION_MODEL = 'gpt-4.1-mini'
  VISION_MAX_TOKENS = 500

  def initialize(api_key: nil)
    @api_key = api_key
    @client = Llm::Client.new(model: VISION_MODEL, api_key: api_key)
  end

  # Routes the attachment to the appropriate processor.
  # Returns a descriptive text string for the LLM, or nil if unprocessable.
  def process_attachment(attachment)
    dispatch_attachment(attachment)
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] Failed to process #{attachment.file_type} attachment ##{attachment.id}: #{e.message}"
    "[#{attachment.file_type} recebido — não foi possível processar]"
  end

  private

  def dispatch_attachment(attachment)
    case attachment.file_type.to_s
    when 'audio'    then process_audio(attachment)
    when 'image'    then process_image(attachment)
    when 'video'    then '[Vídeo recebido — não é possível analisar vídeos no momento]'
    when 'file'     then process_document(attachment)
    when 'location' then process_location(attachment)
    when 'contact'  then '[Cartão de contato recebido]'
    else "[#{attachment.file_type} anexado]"
    end
  end

  # --- Audio: Whisper transcription ---

  def process_audio(attachment)
    cached = attachment.meta&.dig('transcribed_text')
    return "🎤 Transcrição do áudio:\n#{cached}" if cached.present?

    return '[Áudio recebido — arquivo não disponível]' unless attachment.file.attached?

    transcribed_text = transcribe_audio(attachment)
    return '[Áudio recebido — não foi possível transcrever]' if transcribed_text.blank?

    attachment.update!(meta: (attachment.meta || {}).merge('transcribed_text' => transcribed_text))
    "🎤 Transcrição do áudio:\n#{transcribed_text}"
  end

  def transcribe_audio(attachment)
    tempfile = download_to_tempfile(attachment, extension: audio_extension(attachment))
    return nil unless tempfile

    begin
      whisper_transcribe(tempfile.path)
    ensure
      tempfile.close
      tempfile.unlink
    end
  end

  def whisper_transcribe(audio_file_path)
    uri = whisper_uri
    request = build_whisper_request(uri, audio_file_path)
    response = execute_whisper_request(uri, request)

    Rails.logger.info "[MEDIA_PROCESSOR] Whisper response: #{response.code}"
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)['text']
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] Whisper transcription failed: #{e.class} — #{e.message}"
    nil
  end

  def whisper_uri
    base_url = ENV.fetch('LITELLM_BASE_URL', 'http://localhost:4000')
    URI("#{base_url}/v1/audio/transcriptions")
  end

  def build_whisper_request(uri, audio_file_path)
    request = Net::HTTP::Post.new(uri)
    api_key = ENV.fetch('LITELLM_API_KEY', nil)
    request['Authorization'] = "Bearer #{api_key}" if api_key.present?

    File.open(audio_file_path) do |file|
      request.set_form([['file', file], %w[model whisper-1], %w[language pt]], 'multipart/form-data')
    end
    request
  end

  def execute_whisper_request(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 60
    http.request(request)
  end

  def audio_extension(attachment)
    ext = attachment.extension.presence || 'ogg'
    ".#{ext}"
  end

  # --- Image: GPT-4 Vision ---

  def process_image(attachment)
    return '[Imagem recebida — arquivo não disponível]' unless attachment.file.attached?

    image_url = attachment_public_url(attachment)
    return '[Imagem recebida — URL não disponível]' if image_url.blank?

    description = describe_image(image_url)
    return '[Imagem recebida — não foi possível analisar]' if description.blank?

    "🖼️ Imagem recebida — Descrição:\n#{description}"
  end

  def describe_image(image_url)
    messages = [{ role: 'user', content: vision_content(image_url) }]
    response = @client.chat(messages: messages, max_tokens: VISION_MAX_TOKENS)
    response.dig('choices', 0, 'message', 'content')
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] Vision failed: #{e.class} — #{e.message}"
    nil
  end

  def vision_content(image_url)
    description = 'Descreva esta imagem de forma concisa em português. ' \
                  'Se for um documento, extraia o texto. Se for uma foto de um imóvel, descreva-o.'
    [
      { type: 'text', text: description },
      { type: 'image_url', image_url: { url: image_url } }
    ]
  end

  # --- Document: text extraction ---

  def process_document(attachment)
    return '[Documento recebido — arquivo não disponível]' unless attachment.file.attached?

    filename = attachment.file.filename.to_s
    extension = File.extname(filename).downcase

    case extension
    when '.txt', '.csv', '.json', '.md', '.yml', '.yaml', '.xml', '.html'
      extract_text_file(attachment)
    else
      "[📄 Documento recebido: #{filename}]"
    end
  end

  def extract_text_file(attachment)
    content = +''
    attachment.file.blob.open { |io| content = io.read.force_encoding('UTF-8') }
    "📄 Conteúdo do documento (#{attachment.file.filename}):\n#{content.truncate(2000)}"
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] Text extraction failed: #{e.message}"
    "[📄 Documento recebido: #{attachment.file.filename}]"
  end

  # --- Location ---

  def process_location(attachment)
    lat = attachment.coordinates_lat
    lng = attachment.coordinates_long
    title = attachment.fallback_title.presence

    parts = ['📍 Localização compartilhada']
    parts << "Local: #{title}" if title
    parts << "Coordenadas: #{lat}, #{lng}" if lat.present? && lng.present?
    parts.join("\n")
  end

  # --- Helpers ---

  def download_to_tempfile(attachment, extension: '.tmp')
    tempfile = Tempfile.new(['whatsapp_media', extension])
    tempfile.binmode
    attachment.file.blob.open { |io| IO.copy_stream(io, tempfile) }
    tempfile.rewind
    tempfile
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] Download to tempfile failed: #{e.message}"
    tempfile&.close
    tempfile&.unlink
    nil
  end

  def attachment_public_url(attachment)
    url = attachment.download_url
    return nil if url.blank?

    if url.start_with?('/')
      frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
      "#{frontend_url}#{url}"
    else
      url
    end
  end
end
