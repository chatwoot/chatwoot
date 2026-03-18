class Api::V1::Accounts::InboxMessageTemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_whatsapp_channel

  def index
    service = Whatsapp::MessageTemplateService.new(@inbox.channel)
    result = service.list_templates(pagination_options)

    if result[:success]
      render json: {
        templates: result[:templates],
        paging: result[:paging]
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def create
    template_params = extract_template_params
    return render_validation_error('Template name is required') if template_params[:name].blank?
    return render_validation_error('Body text is required') if template_params.dig(:body, :text).blank?

    service = Whatsapp::MessageTemplateService.new(@inbox.channel)
    result = service.create_template(template_params)
    render_template_creation_result(result)
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActionController::ParameterMissing
    render json: { error: 'Template parameters are required' }, status: :unprocessable_entity
  end

  def show
    template_name = params[:id]
    return render_validation_error('Template name is required') if template_name.blank?

    service = Whatsapp::MessageTemplateService.new(@inbox.channel)
    result = service.get_template_status(template_name)

    if result[:success]
      render json: { template: result[:template] }
    else
      render json: { error: result[:error] }, status: :not_found
    end
  end

  PENDING_REVIEW_STATUSES = %w[PENDING IN_APPEAL].freeze
  PERMISSION_ERROR_CODE = 100

  def destroy
    template_name = params[:id]
    template_id = params[:template_id] # hsm_id from Meta API
    return render_validation_error('Template name is required') if template_name.blank?

    service = Whatsapp::MessageTemplateService.new(@inbox.channel)

    # Check template status before deletion and get template ID if not provided
    status_result = service.get_template_status(template_name)
    if status_result[:success]
      template_data = status_result[:template]
      template_status = template_data&.dig(:status)

      if PENDING_REVIEW_STATUSES.include?(template_status)
        return render json: {
          error: 'Cannot delete template while it is under review',
          code: 'TEMPLATE_UNDER_REVIEW',
          status: template_status
        }, status: :unprocessable_entity
      end

      # Use template ID from status result if not provided in params
      template_id ||= template_data&.dig(:id)
    end

    result = service.delete_template(template_name, template_id)

    if result[:success]
      head :no_content
    else
      # Handle permission errors specifically
      if result[:code] == PERMISSION_ERROR_CODE
        render json: {
          error: 'Insufficient permissions to delete this template. Check WhatsApp Business Account permissions.',
          code: 'INSUFFICIENT_PERMISSIONS',
          details: result[:error]
        }, status: :forbidden
      else
        render json: { error: result[:error], code: result[:code] }, status: :unprocessable_entity
      end
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def validate_whatsapp_channel
    return if @inbox.whatsapp?

    render json: { error: 'Message template operations are only available for WhatsApp Cloud channels' },
           status: :bad_request
  end

  def extract_template_params
    template = params.require(:template).permit(
      :name, :language, :category, :parameter_format,
      header: [:format, :text, :example_url, :example],
      body: [:text],
      footer: [:text]
    )

    # Extract examples separately since they have dynamic keys
    # Validate that all example values are strings to prevent injection
    body_examples = sanitize_examples_hash(params.dig(:template, :body, :examples)&.to_unsafe_h)
    header_example = params.dig(:template, :header, :example)

    body_hash = template[:body]&.to_h || {}
    body_hash[:examples] = body_examples if body_examples.present?

    header_hash = template[:header]&.to_h || {}
    header_hash[:example] = header_example if header_example.present?

    {
      name: template[:name],
      language: template[:language] || 'en_US',
      category: template[:category] || 'UTILITY',
      parameter_format: template[:parameter_format] || 'positional',
      header: header_hash.presence,
      body: body_hash,
      footer: template[:footer]&.to_h
    }
  end

  def render_validation_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def render_template_creation_result(result)
    if result[:success]
      render json: { template: result[:template] }, status: :created
    else
      render json: {
        error: result[:error],
        details: parse_whatsapp_error(result[:response_body])
      }, status: :unprocessable_entity
    end
  end

  def parse_whatsapp_error(response_body)
    return nil if response_body.blank?

    begin
      error_data = JSON.parse(response_body)
      whatsapp_error = error_data['error'] || {}

      {
        code: whatsapp_error['code'],
        subcode: whatsapp_error['error_subcode'],
        type: whatsapp_error['type'],
        title: whatsapp_error['error_user_title']
      }.compact
    rescue JSON::ParserError
      nil
    end
  end

  def sanitize_examples_hash(examples)
    return {} if examples.blank?

    # Only allow string keys and string values
    examples.each_with_object({}) do |(key, value), hash|
      next unless key.is_a?(String) || key.is_a?(Symbol)
      next unless value.is_a?(String)

      hash[key.to_s] = value
    end
  end

  def pagination_options
    {
      limit: params[:limit]&.to_i || 20,
      after: params[:after],
      before: params[:before],
      fetch_all: params[:fetch_all] == 'true'
    }
  end
end
