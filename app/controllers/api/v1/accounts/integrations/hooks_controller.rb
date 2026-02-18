class Api::V1::Accounts::Integrations::HooksController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:create, :test_crm_action]
  before_action :check_authorization, except: [:test_crm_action]
  before_action :check_test_authorization, only: [:test_crm_action]

  def create
    @hook = Current.account.hooks.create!(permitted_params)
  end

  def update
    @hook.update!(permitted_params.slice(:status, :settings))
  end

  def process_event
    response = @hook.process_event(params[:event])

    # for cases like an invalid event, or when conversation does not have enough messages
    # for a label suggestion, the response is nil
    if response.nil?
      render json: { message: nil }
    elsif response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: { message: response[:message] }
    end
  end

  def destroy
    @hook.destroy!
    head :ok
  end

  # Test endpoint to manually test CRM actions (Zoho, Salesforce, etc.)
  # POST /api/v1/accounts/:account_id/integrations/hooks/:id/test_crm_action
  # Body: { action_type: 'create_lead', contact_id: 123 }
  def test_crm_action
    @hook = Current.account.hooks.find(params[:id])
    action_type = params[:action_type]

    unless %w[zoho salesforce hubspot kommo].include?(@hook.app_id)
      return render json: { error: 'This hook is not a CRM integration' }, status: :unprocessable_entity
    end

    # Create processor for the CRM
    processor = create_processor(@hook)

    unless processor
      return render json: { error: 'Failed to create CRM processor' }, status: :unprocessable_entity
    end

    # Execute the action with provided params
    result = processor.execute_action(action_type, action_params)

    if result[:success]
      render json: { success: true, result: result }
    else
      render json: { success: false, error: result[:error], result: result }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "CRM test action failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find(params[:id])
  end

  def check_authorization
    authorize(:hook)
  end

  def check_test_authorization
    authorize(:hook, :test_crm_action?)
  end

  def permitted_params
    params.require(:hook).permit(:app_id, :inbox_id, :status, settings: {})
  end

  def create_processor(hook)
    case hook.app_id
    when 'zoho'
      Crm::Zoho::ProcessorService.new(hook)
    when 'salesforce'
      Crm::Salesforce::ProcessorService.new(hook) if defined?(Crm::Salesforce::ProcessorService)
    when 'hubspot'
      Crm::Hubspot::ProcessorService.new(hook) if defined?(Crm::Hubspot::ProcessorService)
    when 'kommo'
      Crm::Kommo::ProcessorService.new(hook) if defined?(Crm::Kommo::ProcessorService)
    else
      nil
    end
  end

  def action_params
    params.permit(
      :contact_id,
      :email,
      :phone,
      :appointment_id,
      :subject,
      :description,
      :due_date,
      :priority,
      :status,
      :owner_id,
      :tag_name,
      :note_text,
      :note_title,
      :send_notification,
      :contact_first_name,
      :contact_last_name,
      lead_custom_fields: {},
      contact_custom_fields: {}
    ).to_h
  end
end
