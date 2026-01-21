# Implements Facebook Graph API Upload
# https://developers.facebook.com/docs/graph-api/guides/upload
class Whatsapp::FacebookUploadService
  SUPPORTED_FORMATS = {
    'IMAGE' => %w[image/jpeg image/jpg image/png],
    'VIDEO' => %w[video/mp4],
    'DOCUMENT' => %w[application/pdf]
  }.freeze

  def initialize(facebook_credentials:)
    @app_id = facebook_credentials[:app_id]
    @access_token = facebook_credentials[:access_token]
    @api_base = "#{facebook_credentials[:api_base]}/#{facebook_credentials[:api_version]}"
  end

  def validate_format!(content_type, format)
    supported_types = SUPPORTED_FORMATS[format]
    return if supported_types&.include?(content_type)

    raise StandardError, "Invalid file type #{content_type} for format #{format}"
  end

  def upload_headers(offset:, content_length:)
    Rails.logger.info "Uploading media chunk with Content-Length: #{content_length}"

    {
      'Authorization' => "Bearer #{@access_token}",
      'file_offset' => offset.to_s,
      'Content-Length' => content_length.to_s
    }
  end

  def upload_media_for_template(blob_id:, format:)
    blob = ActiveStorage::Blob.find_signed(blob_id)
    return { error: 'Media file not found' } unless blob

    validate_format!(blob.content_type, format)

    blob.open do |tempfile|
      upload_file(
        tempfile: tempfile,
        file_name: blob.filename.to_s,
        file_size: blob.byte_size,
        content_type: blob.content_type
      )
    end
  rescue StandardError => e
    Rails.logger.error "Media upload failed: #{e.message}"
    { error: e.message }
  end

  private

  def upload_file(tempfile:, file_name:, file_size:, content_type:)
    session_id = create_upload_session(
      file_name: file_name,
      file_size: file_size,
      content_type: content_type
    )

    return { error: 'Failed to create upload session' } unless session_id

    handle = upload_file_content(
      session_id: session_id,
      tempfile: tempfile
    )

    handle ? { handle: handle } : { error: 'Failed to upload file' }
  end

  def create_upload_session(file_name:, file_size:, content_type:)
    response = HTTParty.post(
      "#{@api_base}/#{@app_id}/uploads",
      query: {
        file_name: file_name,
        file_length: file_size,
        file_type: content_type,
        access_token: @access_token
      }
    )
    handle_session_response(response)
  rescue StandardError => e
    Rails.logger.error "Upload session error: #{e.message}"
    nil
  end

  def upload_file_content(session_id:, tempfile:)
    # directly send session id in path as it already contains `upload`: upload:MTphdHRhY2htZW50...
    Rails.logger.info "upload_headers: #{upload_headers(offset: '0', content_length: tempfile.size).inspect}"
    response = HTTParty.post(
      "#{@api_base}/#{session_id}",
      headers: upload_headers(offset: '0', content_length: tempfile.size),
      body_stream: tempfile
    )
    handle_upload_response(response)
  rescue StandardError => e
    Rails.logger.error "File upload error: #{e.message}"
    nil
  end

  def handle_session_response(response)
    parsed = response.parsed_response
    if response.success? && parsed['id']
      # meta returns id in format: "upload:MTphdHRhY2htZW50..."
      return parsed['id']
    end

    Rails.logger.error "Upload session failed: #{parsed.dig('error', 'message')}"
    nil
  end

  def handle_upload_response(response)
    parsed = response.parsed_response
    return parsed['h'] if response.success? && parsed['h']

    Rails.logger.info parsed.inspect

    Rails.logger.error "File upload failed: #{parsed.dig('error', 'message')}"
    nil
  end
end
