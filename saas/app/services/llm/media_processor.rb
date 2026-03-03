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
    uri, api_key = whisper_config

    # File must stay open during the entire HTTP request lifecycle
    file = File.open(audio_file_path, 'rb')
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{api_key}" if api_key.present?
    request.set_form([['file', file], %w[model whisper-1], %w[language pt]], 'multipart/form-data')

    response = execute_http(uri, request)
    Rails.logger.info "[MEDIA_PROCESSOR] Whisper response: #{response.code}"
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)['text']
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] Whisper transcription failed: #{e.class} — #{e.message}"
    nil
  ensure
    file&.close
  end

  def whisper_config
    base_url = ENV.fetch('LITELLM_BASE_URL', 'http://localhost:4000')
    [URI("#{base_url}/v1/audio/transcriptions"), ENV.fetch('LITELLM_API_KEY', nil)]
  end

  def execute_http(uri, request)
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

    base64_url = encode_attachment_as_base64(attachment)
    return '[Imagem recebida — não foi possível codificar]' if base64_url.blank?

    description = describe_image(base64_url)
    return '[Imagem recebida — não foi possível analisar]' if description.blank?

    "🖼️ Imagem recebida — Descrição:\n#{description}"
  end

  def describe_image(image_data_url)
    description = 'Descreva esta imagem de forma concisa em português. ' \
                  'Se for um documento, extraia o texto. Se for uma foto de um imóvel, descreva-o.'
    messages = [{
      role: 'user',
      content: [
        { type: 'text', text: description },
        { type: 'image_url', image_url: { url: image_data_url } }
      ]
    }]
    response = @client.chat(messages: messages, max_tokens: VISION_MAX_TOKENS)
    response.dig('choices', 0, 'message', 'content')
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] Vision failed: #{e.class} — #{e.message}"
    nil
  end

  def encode_attachment_as_base64(attachment)
    content_type = attachment.file.content_type || 'image/jpeg'
    raw = nil
    attachment.file.blob.open { |io| raw = io.read }
    encoded = Base64.strict_encode64(raw)
    "data:#{content_type};base64,#{encoded}"
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] Base64 encoding failed: #{e.message}"
    nil
  end

  # --- Document: text extraction ---

  def process_document(attachment)
    return '[Documento recebido — arquivo não disponível]' unless attachment.file.attached?

    filename = attachment.file.filename.to_s
    extension = File.extname(filename).downcase

    case extension
    when '.txt', '.csv', '.json', '.md', '.yml', '.yaml', '.xml', '.html'
      extract_text_file(attachment)
    when '.pdf'
      extract_pdf_file(attachment)
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

  def extract_pdf_file(attachment)
    tempfile = download_to_tempfile(attachment, extension: '.pdf')
    return "[📄 Documento PDF recebido: #{attachment.file.filename}]" unless tempfile

    text = read_pdf_text(tempfile, attachment.file.filename)
    format_pdf_result(text, attachment.file.filename)
  rescue StandardError => e
    Rails.logger.warn "[MEDIA_PROCESSOR] PDF extraction failed: #{e.class} — #{e.message}"
    "[📄 Documento PDF recebido: #{attachment.file.filename}]"
  end

  def read_pdf_text(tempfile, filename)
    reader = PDF::Reader.new(tempfile.path)
    text = reader.pages.map(&:text).join("\n").strip.truncate(3000)
    Rails.logger.info "[MEDIA_PROCESSOR] PDF extracted #{text.length} chars from #{filename}"
    text
  ensure
    tempfile.close
    tempfile.unlink
  end

  def format_pdf_result(text, filename)
    if text.present?
      "📄 Conteúdo do PDF (#{filename}):\n#{text}"
    else
      "[📄 Documento PDF recebido (sem texto extraível): #{filename}]"
    end
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
end
