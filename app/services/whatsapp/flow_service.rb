# Service for managing WhatsApp Flows via the Meta Graph API.
#
# Meta Flows API reference:
#   - Create:    POST   /{waba_id}/flows
#   - Update:    POST   /{flow_id}/assets  (uploads flow JSON)
#   - Publish:   POST   /{flow_id}/publish
#   - Get:       GET    /{flow_id}
#   - List:      GET    /{waba_id}/flows
#   - Delete:    DELETE /{flow_id}
#   - Deprecate: POST   /{flow_id}/deprecate
#
class Whatsapp::FlowService
  attr_reader :whatsapp_flow, :inbox

  def initialize(whatsapp_flow: nil, inbox: nil)
    @whatsapp_flow = whatsapp_flow
    @inbox = inbox || whatsapp_flow&.inbox
    @channel = @inbox&.channel
    @api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
  end

  # Create a flow on Meta and store the flow_id locally
  def create
    response = post(waba_path('flows'), {
                      name: whatsapp_flow.name,
                      categories: whatsapp_flow.categories.presence || ['OTHER']
                    })

    return error_result(response) unless response.success?

    whatsapp_flow.update!(flow_id: response['id'])
    upload_flow_json if whatsapp_flow.screens.any?
    success_result
  end

  # Upload the flow JSON definition to Meta
  def upload_flow_json
    return error_result_message('No flow_id — create the flow on Meta first') if whatsapp_flow.flow_id.blank?

    # Meta expects multipart form: file=<flow.json>, name="flow.json", asset_type="FLOW_JSON"
    response = HTTParty.post(
      "#{flow_path}/assets",
      headers: auth_header,
      body: {
        file: flow_json_upload_io,
        name: 'flow.json',
        asset_type: 'FLOW_JSON'
      }
    )

    return error_result(response) unless response.success?

    update_validation_errors(response)
    success_result
  end

  # Publish the flow — makes it immutable
  def publish
    return error_result_message('Flow is not in draft status') unless whatsapp_flow.draft?
    return error_result_message('No flow_id') if whatsapp_flow.flow_id.blank?

    response = post(flow_path('publish'), {})
    return error_result(response) unless response.success?

    whatsapp_flow.update!(status: :published)
    success_result
  end

  # Deprecate a published flow
  def deprecate
    return error_result_message('Flow is not published') unless whatsapp_flow.published?

    response = post(flow_path('deprecate'), {})
    return error_result(response) unless response.success?

    whatsapp_flow.update!(status: :deprecated)
    success_result
  end

  # Delete the flow on Meta and locally
  def delete
    if whatsapp_flow.flow_id.present?
      response = HTTParty.delete(
        flow_path,
        headers: api_headers
      )
      return error_result(response) unless response.success? || response.code == 404
    end

    whatsapp_flow.destroy!
    success_result
  end

  # Get flow details from Meta and sync locally
  def sync
    return error_result_message('No flow_id') if whatsapp_flow.flow_id.blank?

    response = HTTParty.get(
      "#{flow_path}?fields=id,name,status,categories,validation_errors,preview.invalidate(false),json_version",
      headers: api_headers
    )
    return error_result(response) unless response.success?

    sync_from_response(response)
    success_result
  end

  # Get preview URL from Meta
  def preview
    return error_result_message('No flow_id') if whatsapp_flow.flow_id.blank?

    response = HTTParty.get(
      "#{flow_path}?fields=preview",
      headers: api_headers
    )
    return error_result(response) unless response.success?

    preview_url = response.dig('preview', 'preview_url')
    whatsapp_flow.update!(preview_url: preview_url) if preview_url.present?
    { success: true, preview_url: preview_url }
  end

  # List all flows from Meta for this WABA
  def list_remote
    response = HTTParty.get(
      "#{waba_path('flows')}?fields=id,name,status,categories,validation_errors",
      headers: api_headers
    )
    return error_result(response) unless response.success?

    { success: true, flows: response['data'] || [] }
  end

  private

  def post(url, body)
    HTTParty.post(url, headers: api_headers, body: body.to_json)
  end

  def flow_path(suffix = nil)
    path = "#{api_base_path}/#{@api_version}/#{whatsapp_flow.flow_id}"
    suffix ? "#{path}/#{suffix}" : path
  end

  def waba_path(suffix = nil)
    path = "#{api_base_path}/#{@api_version}/#{business_account_id}"
    suffix ? "#{path}/#{suffix}" : path
  end

  def flow_json_upload_io
    json_string = whatsapp_flow.flow_json.to_json
    UploadIO.new(StringIO.new(json_string), 'application/json', 'flow.json')
  end

  def update_validation_errors(response)
    errors = response['validation_errors'] || []
    whatsapp_flow.update!(validation_errors: errors)
  end

  def sync_from_response(response)
    attrs = {}
    attrs[:status] = map_meta_status(response['status']) if response['status'].present?
    attrs[:categories] = response['categories'] if response['categories'].present?
    attrs[:validation_errors] = response['validation_errors'] || []
    attrs[:preview_url] = response.dig('preview', 'preview_url') if response.dig('preview', 'preview_url').present?
    whatsapp_flow.update!(attrs)
  end

  def map_meta_status(meta_status)
    case meta_status.to_s.downcase
    when 'draft', '' then :draft
    when 'published' then :published
    when 'deprecated' then :deprecated
    when 'blocked' then :blocked
    when 'throttled' then :throttled
    end
  end

  def success_result
    { success: true, flow: whatsapp_flow }
  end

  def error_result(response)
    message = parse_error(response)
    Rails.logger.error "WhatsApp Flow API error: #{response.code} - #{response.body}"
    { success: false, error: message }
  end

  def error_result_message(message)
    { success: false, error: message }
  end

  def parse_error(response)
    parsed = response.parsed_response
    return parsed['error']['message'] if parsed.is_a?(Hash) && parsed.dig('error', 'message').present?

    'Flow operation failed'
  rescue StandardError
    'Flow operation failed'
  end

  def business_account_id
    @channel.provider_config['business_account_id']
  end

  def api_headers
    {
      'Authorization' => "Bearer #{@channel.provider_config['api_key']}",
      'Content-Type' => 'application/json'
    }
  end

  def auth_header
    { 'Authorization' => "Bearer #{@channel.provider_config['api_key']}" }
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
