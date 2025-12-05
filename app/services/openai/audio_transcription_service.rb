require 'httparty'
require 'down'
require 'tempfile'

class Openai::AudioTranscriptionService
  include HTTParty
  base_uri 'https://api.openai.com/v1'

  def initialize(audio_url: nil, attachment: nil, account: nil)
    @audio_url = audio_url
    @attachment = attachment
    @account = account
    @api_key = resolve_api_key
  end

  def process
    if @api_key.blank?
      Rails.logger.info 'OpenAI API key is not configured'
      return nil
    end

    Rails.logger.debug { "Downloading audio file from: #{@audio_url}" }
    audio_file = download_audio_file

    unless audio_file
      Rails.logger.error 'Failed to download audio file'
      return nil
    end

    Rails.logger.debug 'Making API request to OpenAI for transcription'
    transcription = request_transcription(audio_file)

    if transcription
      Rails.logger.debug 'Successfully received transcription from OpenAI'
      transcription
    else
      Rails.logger.error 'Failed to get transcription from OpenAI'
      nil
    end
  ensure
    cleanup_file(audio_file)
  end

  private

  def download_audio_file
    # If we have an attachment, open the blob directly (avoids corrupted filename issues)
    if @attachment&.file&.attached?
      Rails.logger.debug 'Opening audio file from ActiveStorage blob'
      return open_blob_file(@attachment.file)
    end

    # Fallback to URL download for backward compatibility
    file_url = if @audio_url.start_with?('http')
                 @audio_url
               else
                 "#{ENV.fetch('FRONTEND_URL', nil)}#{@audio_url}"
               end

    Rails.logger.debug { "Downloading from: #{file_url}" }
    tempfile = Down.download(file_url)

    # Sanitize filename to remove mime type parameters (e.g., "; codecs=opus")
    # OpenAI rejects files with invalid extensions
    sanitized_file = sanitize_audio_filename(tempfile)

    Rails.logger.debug { "Audio file downloaded to: #{sanitized_file.path}" }
    sanitized_file
  rescue ActiveStorage::FileNotFoundError => e
    Rails.logger.error "Audio file not found in storage: #{e.message}"
    raise Openai::Exceptions::InvalidFileError, "Audio file not found: #{e.message}"
  rescue Down::Error, Errno::ENOENT, OpenURI::HTTPError => e
    Rails.logger.error "Network error downloading audio: #{e.message}"
    raise Openai::Exceptions::NetworkError, "Failed to download audio file: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error downloading audio file: #{e.message}\n#{e.backtrace.join("\n")}"
    raise Openai::Exceptions::NetworkError, "Unexpected error downloading audio: #{e.message}"
  end

  def request_transcription(audio_file)
    Rails.logger.info "Sending file to OpenAI: #{audio_file.path}"
    Rails.logger.info "File size: #{File.size(audio_file.path)} bytes"
    Rails.logger.info "File extension: #{File.extname(audio_file.path)}"

    # Read first few bytes to check if file is valid
    audio_file.rewind
    file_header = audio_file.read(20)
    audio_file.rewind
    Rails.logger.info "File header (hex): #{file_header.unpack1('H*')}"

    # Ensure the file object has a proper filename with extension for HTTParty
    # HTTParty needs to know the content type from the filename
    def audio_file.original_filename
      File.basename(path)
    end

    response = self.class.post(
      '/audio/transcriptions',
      headers: {
        'Authorization' => "Bearer #{@api_key}"
      },
      body: {
        model: 'whisper-1',
        file: audio_file,
        response_format: 'verbose_json'
      },
      multipart: true
    )

    if response.success?
      parsed = response.parsed_response
      {
        text: parsed['text'],
        language: parsed['language'],
        duration: parsed['duration']
      }
    else
      handle_error_response(response)
    end
  rescue StandardError => e
    Rails.logger.error "Error in transcription request: #{e.message}\n#{e.backtrace.join("\n")}"
    raise
  end

  def handle_error_response(response)
    error_message = "#{response.code} - #{response.body}"

    case response.code
    when 429
      raise Openai::Exceptions::RateLimitError, "Rate limit exceeded: #{error_message}"
    when 400
      raise Openai::Exceptions::InvalidFileError, "Invalid file: #{error_message}"
    when 401, 403
      raise Openai::Exceptions::AuthenticationError, "Authentication failed: #{error_message}"
    when 500..599
      raise Openai::Exceptions::NetworkError, "Server error: #{error_message}"
    else
      raise Openai::Exceptions::TranscriptionError, "Unknown error: #{error_message}"
    end
  end

  def open_blob_file(attached_file)
    # Get the blob's content type to determine extension
    content_type = attached_file.content_type
    extension = mime_type_to_extension(content_type)

    Rails.logger.info "Opening blob with content type: #{content_type}, extension: #{extension}"

    # Create a clean tempfile with proper extension
    tempfile = Tempfile.new(['audio', ".#{extension}"])
    tempfile.binmode

    # Download blob content directly to tempfile
    attached_file.download do |chunk|
      tempfile.write(chunk)
    end

    tempfile.rewind
    Rails.logger.debug { "Blob downloaded to: #{tempfile.path}" }
    tempfile
  end

  def mime_type_to_extension(content_type)
    # Map common audio mime types to extensions
    # IMPORTANT: Use extensions that OpenAI Whisper API supports
    case content_type
    when 'audio/ogg', 'audio/ogg; codecs=opus', 'audio/opus'
      'ogg'  # OpenAI doesn't support .opus, but accepts .ogg
    when 'audio/mpeg', 'audio/mp3'
      'mp3'
    when 'audio/mp4', 'audio/m4a'
      'm4a'
    when 'audio/wav', 'audio/wave'
      'wav'
    when 'audio/webm'
      'webm'
    when 'audio/flac'
      'flac'
    else
      # Fallback: extract from content type, map opus to ogg
      extracted = content_type.split('/').last.split(';').first
      extracted == 'opus' ? 'ogg' : (extracted || 'ogg')
    end
  end

  def sanitize_audio_filename(tempfile)
    original_path = tempfile.path
    original_basename = File.basename(original_path)

    # Check if filename contains mime type parameters or other invalid characters
    # Examples: "file.ogg; codecs=opus" or "file.ogg-%20codecs=opus"
    if original_basename.match?(/[;%]/)
      Rails.logger.debug { "Sanitizing filename: #{original_basename}" }

      # Extract the clean extension (everything before ';', '%', or other invalid chars)
      clean_extension = original_basename.split(/[;%]/).first.split('.').last

      # Create a new tempfile with a clean name
      new_tempfile = Tempfile.new(['audio', ".#{clean_extension}"])
      new_tempfile.binmode

      # Copy content from original to new file
      IO.copy_stream(tempfile, new_tempfile)
      new_tempfile.rewind

      # Close and delete the original tempfile
      tempfile.close
      tempfile.unlink

      Rails.logger.debug { "Sanitized filename to: #{File.basename(new_tempfile.path)}" }
      new_tempfile
    else
      tempfile
    end
  end

  def cleanup_file(file)
    return unless file

    Rails.logger.debug 'Cleaning up temporary audio file'
    file.close
    file.unlink
  rescue StandardError => e
    Rails.logger.error "Error cleaning up file: #{e.message}"
  end

  def resolve_api_key
    # 1. Try integration hook first
    if @account
      integration = @account.hooks.find_by(app_id: 'openai', status: 'enabled')
      if integration&.settings&.dig('api_key').present?
        Rails.logger.debug { "Using OpenAI API key from integration for account #{@account.id}" }
        return integration.settings['api_key']
      end
    end

    # 2. Fall back to ENV
    Rails.logger.debug 'Using OpenAI API key from environment variable'
    ENV.fetch('OPENAI_API_KEY', nil)
  end
end
