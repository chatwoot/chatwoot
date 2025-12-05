class Api::V1::Accounts::InboxCsatTemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_whatsapp_channel

  def show
    template = @inbox.csat_config&.dig('template')
    return render json: { template_exists: false } unless template

    template_name = template['name'] || "customer_satisfaction_survey_inbox_#{@inbox.id}"
    status_result = @inbox.channel.provider_service.get_template_status(template_name)

    render_template_status_response(status_result, template_name)
  rescue StandardError => e
    Rails.logger.error "Error fetching CSAT template status: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  def create
    template_params = extract_template_params
    return render_missing_message_error if template_params[:message].blank?

    # Delete existing template even though we are using a new one.
    # We don't want too many templates in the business portfolio, but the create operation shouldn't fail if deletion fails.
    delete_existing_template_if_needed

    result = create_template_via_provider(template_params)
    render_template_creation_result(result)
  rescue ActionController::ParameterMissing
    render json: { error: 'Template parameters are required' }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "Error creating CSAT template: #{e.message}"
    render json: { error: 'Template creation failed' }, status: :internal_server_error
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def validate_whatsapp_channel
    return if @inbox.whatsapp?

    render json: { error: 'CSAT template operations only available for WhatsApp channels' },
           status: :bad_request
  end

  def extract_template_params
    params.require(:template).permit(:message, :button_text, :language)
  end

  def render_missing_message_error
    render json: { error: 'Message is required' }, status: :unprocessable_entity
  end

  def create_template_via_provider(template_params)
    template_config = {
      message: template_params[:message],
      button_text: template_params[:button_text] || 'Please rate us',
      base_url: ENV.fetch('FRONTEND_URL', 'http://localhost:3000'),
      language: template_params[:language] || 'en',
      template_name: "customer_satisfaction_survey_inbox_#{@inbox.id}"
    }

    @inbox.channel.provider_service.create_csat_template(template_config)
  end

  def render_template_creation_result(result)
    if result[:success]
      render_successful_template_creation(result)
    else
      render_failed_template_creation(result)
    end
  end

  def render_successful_template_creation(result)
    render json: {
      template: {
        name: result[:template_name],
        template_id: result[:template_id],
        status: 'PENDING',
        language: result[:language] || 'en'
      }
    }, status: :created
  end

  def render_failed_template_creation(result)
    whatsapp_error = parse_whatsapp_error(result[:response_body])
    error_message = whatsapp_error[:user_message] || result[:error]

    render json: {
      error: error_message,
      details: whatsapp_error[:technical_details]
    }, status: :unprocessable_entity
  end

  def delete_existing_template_if_needed
    template = @inbox.csat_config&.dig('template')
    return true if template.blank?

    template_name = template['name']
    return true if template_name.blank?

    template_status = @inbox.channel.provider_service.get_template_status(template_name)
    return true unless template_status[:success]

    deletion_result = @inbox.channel.provider_service.delete_csat_template(template_name)
    if deletion_result[:success]
      Rails.logger.info "Deleted existing CSAT template '#{template_name}' for inbox #{@inbox.id}"
      true
    else
      Rails.logger.warn "Failed to delete existing CSAT template '#{template_name}' for inbox #{@inbox.id}: #{deletion_result[:response_body]}"
      false
    end
  rescue StandardError => e
    Rails.logger.error "Error during template deletion for inbox #{@inbox.id}: #{e.message}"
    false
  end

  def render_template_status_response(status_result, template_name)
    if status_result[:success]
      render json: {
        template_exists: true,
        template_name: template_name,
        status: status_result[:template][:status],
        template_id: status_result[:template][:id]
      }
    else
      render json: {
        template_exists: false,
        error: 'Template not found'
      }
    end
  end

  def parse_whatsapp_error(response_body)
    return { user_message: nil, technical_details: nil } if response_body.blank?

    begin
      error_data = JSON.parse(response_body)
      whatsapp_error = error_data['error'] || {}

      user_message = whatsapp_error['error_user_msg'] || whatsapp_error['message']
      technical_details = {
        code: whatsapp_error['code'],
        subcode: whatsapp_error['error_subcode'],
        type: whatsapp_error['type'],
        title: whatsapp_error['error_user_title']
      }.compact

      { user_message: user_message, technical_details: technical_details }
    rescue JSON::ParserError
      { user_message: nil, technical_details: response_body }
    end
  end
end
