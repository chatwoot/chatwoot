class Api::V1::Accounts::InboxCsatTemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_whatsapp_channel

  def show
    service = CsatTemplateManagementService.new(@inbox)
    result = service.template_status

    if result[:service_error]
      render json: { error: result[:service_error] }, status: :internal_server_error
    else
      render json: result
    end
  end

  def create
    template_params = extract_template_params
    return render_missing_message_error if template_params[:message].blank?

    service = CsatTemplateManagementService.new(@inbox)
    result = service.create_template(template_params)
    render_template_creation_result(result)
  rescue ActionController::ParameterMissing
    render json: { error: 'Template parameters are required' }, status: :unprocessable_entity
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def validate_whatsapp_channel
    return if @inbox.whatsapp? || @inbox.twilio_whatsapp?

    render json: { error: 'CSAT template operations only available for WhatsApp and Twilio WhatsApp channels' },
           status: :bad_request
  end

  def extract_template_params
    params.require(:template).permit(:message, :button_text, :language)
  end

  def render_missing_message_error
    render json: { error: 'Message is required' }, status: :unprocessable_entity
  end

  def render_template_creation_result(result)
    if result[:success]
      render_successful_template_creation(result)
    elsif result[:service_error]
      render json: { error: result[:service_error] }, status: :internal_server_error
    else
      render_failed_template_creation(result)
    end
  end

  def render_successful_template_creation(result)
    if @inbox.twilio_whatsapp?
      render json: {
        template: {
          friendly_name: result[:friendly_name],
          content_sid: result[:content_sid],
          status: result[:status] || 'pending',
          language: result[:language] || 'en'
        }
      }, status: :created
    else
      render json: {
        template: {
          name: result[:template_name],
          template_id: result[:template_id],
          status: 'PENDING',
          language: result[:language] || 'en'
        }
      }, status: :created
    end
  end

  def render_failed_template_creation(result)
    whatsapp_error = parse_whatsapp_error(result[:response_body])
    error_message = whatsapp_error[:user_message] || result[:error]

    render json: {
      error: error_message,
      details: whatsapp_error[:technical_details]
    }, status: :unprocessable_entity
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
