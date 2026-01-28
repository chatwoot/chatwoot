class Twilio::CsatTemplateService
  DEFAULT_BUTTON_TEXT = 'Please rate us'.freeze
  DEFAULT_LANGUAGE = 'en'.freeze
  TEMPLATE_CATEGORY = 'UTILITY'.freeze
  TEMPLATE_STATUS_PENDING = 'PENDING'.freeze
  TEMPLATE_CONTENT_TYPE = 'twilio/call-to-action'.freeze

  def initialize(twilio_channel)
    @twilio_channel = twilio_channel
    @api_client = Twilio::CsatTemplateApiClient.new(twilio_channel)
  end

  def create_template(template_config)
    base_name = template_config[:template_name]
    template_name = generate_template_name(base_name)
    template_config_with_name = template_config.merge(template_name: template_name)

    request_body = build_template_request_body(template_config_with_name)

    # Step 1: Create template
    response = @api_client.create_template(request_body)

    return process_template_creation_response(response, template_config_with_name) unless response.success? && response['sid']

    # Step 2: Submit for WhatsApp approval using the approval_create URL
    approval_url = response.dig('links', 'approval_create')

    if approval_url.present?
      approval_response = submit_for_whatsapp_approval(approval_url, template_config_with_name[:template_name])
      process_approval_response(approval_response, response, template_config_with_name)
    else
      Rails.logger.warn 'No approval_create URL provided in template creation response'
      # Fallback if no approval URL provided
      process_template_creation_response(response, template_config_with_name)
    end
  end

  def delete_template(_template_name = nil, content_sid = nil)
    content_sid ||= current_template_sid_from_config
    return { success: false, error: 'No template to delete' } unless content_sid

    response = @api_client.delete_template(content_sid)
    { success: response.success?, response_body: response.body }
  end

  def get_template_status(content_sid)
    return { success: false, error: 'No content SID provided' } unless content_sid

    template_response = fetch_template_details(content_sid)
    return template_response unless template_response[:success]

    approval_response = fetch_approval_status(content_sid)
    build_template_status_response(content_sid, template_response[:data], approval_response)
  rescue StandardError => e
    Rails.logger.error "Error fetching Twilio template status: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def fetch_template_details(content_sid)
    response = @api_client.fetch_template(content_sid)

    if response.success?
      { success: true, data: response }
    else
      Rails.logger.error "Failed to get template details: #{response.code} - #{response.body}"
      { success: false, error: 'Template not found' }
    end
  end

  def fetch_approval_status(content_sid)
    @api_client.fetch_approval_status(content_sid)
  end

  def build_template_status_response(content_sid, template_response, approval_response)
    if approval_response.success? && approval_response['whatsapp']
      build_approved_template_response(content_sid, template_response, approval_response['whatsapp'])
    else
      build_pending_template_response(content_sid, template_response)
    end
  end

  def build_approved_template_response(content_sid, template_response, whatsapp_data)
    {
      success: true,
      template: {
        content_sid: content_sid,
        friendly_name: whatsapp_data['name'] || template_response['friendly_name'],
        status: whatsapp_data['status'] || 'pending',
        language: template_response['language'] || 'en'
      }
    }
  end

  def build_pending_template_response(content_sid, template_response)
    {
      success: true,
      template: {
        content_sid: content_sid,
        friendly_name: template_response['friendly_name'],
        status: 'pending',
        language: template_response['language'] || 'en'
      }
    }
  end

  def generate_template_name(base_name)
    current_template_name = current_template_name_from_config
    CsatTemplateNameService.generate_next_template_name(base_name, @twilio_channel.inbox.id, current_template_name)
  end

  def current_template_name_from_config
    @twilio_channel.inbox.csat_config&.dig('template', 'friendly_name')
  end

  def current_template_sid_from_config
    @twilio_channel.inbox.csat_config&.dig('template', 'content_sid')
  end

  def template_exists_in_config?
    content_sid = current_template_sid_from_config
    friendly_name = current_template_name_from_config

    content_sid.present? && friendly_name.present?
  end

  def build_template_request_body(template_config)
    {
      friendly_name: template_config[:template_name],
      language: template_config[:language] || DEFAULT_LANGUAGE,
      variables: {
        '1' => '12345' # Example conversation UUID
      },
      types: {
        TEMPLATE_CONTENT_TYPE => {
          body: template_config[:message],
          actions: [
            {
              type: 'URL',
              title: template_config[:button_text] || DEFAULT_BUTTON_TEXT,
              url: "#{template_config[:base_url]}/survey/responses/{{1}}"
            }
          ]
        }
      }
    }
  end

  def submit_for_whatsapp_approval(approval_url, template_name)
    @api_client.submit_for_approval(approval_url, template_name, TEMPLATE_CATEGORY)
  end

  def process_template_creation_response(response, template_config = {})
    if response.success? && response['sid']
      {
        success: true,
        content_sid: response['sid'],
        friendly_name: template_config[:template_name],
        language: template_config[:language] || DEFAULT_LANGUAGE,
        status: TEMPLATE_STATUS_PENDING
      }
    else
      Rails.logger.error "Twilio template creation failed: #{response.code} - #{response.body}"
      {
        success: false,
        error: 'Template creation failed',
        response_body: response.body
      }
    end
  end

  def process_approval_response(approval_response, creation_response, template_config)
    if approval_response.success?
      build_successful_approval_response(approval_response, creation_response, template_config)
    else
      build_failed_approval_response(approval_response, creation_response, template_config)
    end
  end

  def build_successful_approval_response(approval_response, creation_response, template_config)
    approval_data = approval_response.parsed_response
    {
      success: true,
      content_sid: creation_response['sid'],
      friendly_name: template_config[:template_name],
      language: template_config[:language] || DEFAULT_LANGUAGE,
      status: TEMPLATE_STATUS_PENDING,
      approval_sid: approval_data['sid'],
      whatsapp_status: approval_data.dig('whatsapp', 'status') || TEMPLATE_STATUS_PENDING
    }
  end

  def build_failed_approval_response(approval_response, creation_response, template_config)
    Rails.logger.error "Twilio template approval submission failed: #{approval_response.code} - #{approval_response.body}"
    {
      success: true,
      content_sid: creation_response['sid'],
      friendly_name: template_config[:template_name],
      language: template_config[:language] || DEFAULT_LANGUAGE,
      status: 'created'
    }
  end
end
