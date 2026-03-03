# Uploads an ActiveStorage blob to Meta's Resumable Upload API
# and returns a handle suitable for use in template header_handle.
#
# Meta docs: https://developers.facebook.com/docs/graph-api/guides/upload
#
# Flow:
#   1. Create upload session: POST /{app_id}/uploads
#   2. Upload file bytes:     POST /{session_id}
#   3. Returns handle string for header_handle
class Whatsapp::FacebookUploadService
  def initialize(blob_signed_id:, whatsapp_channel:)
    @blob = ActiveStorage::Blob.find_signed(blob_signed_id)
    @channel = whatsapp_channel
    @access_token = @channel.provider_config['api_key']
    @api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
    @app_id = GlobalConfigService.load('WHATSAPP_APP_ID', '')
  end

  def perform
    session = create_upload_session
    upload_file_data(session['id'])
  end

  private

  def create_upload_session
    response = HTTParty.post(
      "#{base_url}/#{@api_version}/#{@app_id}/uploads",
      headers: auth_headers,
      body: {
        file_length: @blob.byte_size,
        file_type: @blob.content_type,
        file_name: @blob.filename.to_s
      }
    )

    raise "Upload session creation failed: #{response.body}" unless response.success?

    response.parsed_response
  end

  def upload_file_data(session_id)
    file_data = @blob.download

    response = HTTParty.post(
      "#{base_url}/#{@api_version}/#{session_id}",
      headers: {
        'Authorization' => "OAuth #{@access_token}",
        'file_offset' => '0',
        'Content-Type' => @blob.content_type
      },
      body: file_data
    )

    raise "File upload failed: #{response.body}" unless response.success?

    response.parsed_response['h']
  end

  def auth_headers
    {
      'Authorization' => "Bearer #{@access_token}"
    }
  end

  def base_url
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
