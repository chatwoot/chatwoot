class Api::V1::Accounts::VapiAgentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_vapi_agent, only: [:show, :update, :destroy]

  def index
    @vapi_agents = current_account.vapi_agents.includes(:inbox)
    render json: {
      data: @vapi_agents.map { |agent| format_vapi_agent(agent) },
      meta: {
        total_count: @vapi_agents.count
      }
    }
  end

  def show
    render json: { data: format_vapi_agent(@vapi_agent) }
  end

  def create
    @vapi_agent = Vapi::AgentCreatorService.new(
      account: current_account,
      params: create_params
    ).perform

    render json: { data: format_vapi_agent(@vapi_agent) }, status: :created
  rescue StandardError => e
    Rails.logger.error "Failed to create Vapi agent: #{e.message}"
    render json: { error: "Failed to create agent: #{e.message}" }, status: :unprocessable_entity
  end

  def update
    Vapi::AgentUpdaterService.new(
      vapi_agent: @vapi_agent,
      params: update_params
    ).perform

    render json: { data: format_vapi_agent(@vapi_agent) }
  rescue StandardError => e
    Rails.logger.error "Failed to update Vapi agent: #{e.message}"
    render json: { error: "Failed to update agent: #{e.message}" }, status: :unprocessable_entity
  end

  def destroy
    @vapi_agent.destroy
    head :no_content
  end

  def fetch_from_vapi
    vapi_agent_id = params[:vapi_agent_id]
    inbox_id = params[:inbox_id]

    # Check inputs
    return render json: { error: 'Vapi Agent ID is required' }, status: :unprocessable_entity if vapi_agent_id.blank?

    return render json: { error: 'Inbox ID is required' }, status: :unprocessable_entity if inbox_id.blank?

    # Fetch agent data from Vapi (without creating)
    api_client = Vapi::ApiClient.new
    vapi_data = api_client.get_agent(vapi_agent_id)

    # Log the response
    Rails.logger.info '=' * 80
    Rails.logger.info "Fetch from Vapi - Agent ID: #{vapi_agent_id}"
    Rails.logger.info "Vapi Response: #{vapi_data.inspect}"
    Rails.logger.info '=' * 80

    # Check if agent already exists
    existing_agent = current_account.vapi_agents.find_by(vapi_agent_id: vapi_agent_id)
    if existing_agent.present?
      return render json: {
        error: 'Agent already exists in this account',
        existing: true,
        agent_id: existing_agent.id
      }, status: :unprocessable_entity
    end

    # Extract form data
    form_data = extract_form_data_from_vapi(vapi_data, vapi_agent_id)
    Rails.logger.info "Extracted form data: #{form_data.inspect}"

    render json: { data: form_data }, status: :ok
  rescue StandardError => e
    Rails.logger.error "Failed to fetch from Vapi: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def import_from_vapi
    vapi_agent_id = params[:vapi_agent_id]
    inbox_id = params[:inbox_id]

    result = Vapi::AgentImporterService.new(
      account: current_account,
      vapi_agent_id: vapi_agent_id,
      inbox_id: inbox_id
    ).perform

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    elsif result[:agent]
      render json: { data: format_vapi_agent(result[:agent]) }, status: :created
    else
      render json: { error: 'Unknown error occurred' }, status: :internal_server_error
    end
  end

  private

  def set_vapi_agent
    @vapi_agent = current_account.vapi_agents.find(params[:id])
  end

  def create_params
    params.permit(
      :name,
      :inbox_id,
      :phone_number,
      :active,
      :first_message,
      :system_prompt,
      :voice_provider,
      :voice_id,
      :model_provider,
      :model_name,
      :transcriber_provider,
      :transcriber_language
    )
  end

  def update_params
    params.permit(
      :name,
      :inbox_id,
      :phone_number,
      :active,
      :first_message,
      :system_prompt,
      :voice_provider,
      :voice_id,
      :model_provider,
      :model_name,
      :transcriber_provider,
      :transcriber_language
    )
  end

  def format_vapi_agent(agent)
    {
      id: agent.id,
      name: agent.name,
      vapi_agent_id: agent.vapi_agent_id,
      phone_number: agent.phone_number,
      active: agent.active,
      settings: agent.settings,
      inbox: if agent.inbox
               {
                 id: agent.inbox.id,
                 name: agent.inbox.name
               }
             end,
      created_at: agent.created_at,
      updated_at: agent.updated_at
    }
  end

  def check_authorization
    authorize :vapi_agent, :show?
  end

  def extract_form_data_from_vapi(vapi_data, vapi_agent_id)
    # Try multiple possible field names for flexibility
    first_message = vapi_data['firstMessage'] || vapi_data['first_message']

    # Extract system prompt from model messages
    system_prompt = extract_system_prompt_from_vapi(vapi_data)

    # Extract voice configuration
    voice_provider = vapi_data.dig('voice', 'provider')
    voice_id = vapi_data.dig('voice', 'voiceId') || vapi_data.dig('voice', 'voice_id')

    # Extract model configuration
    model_provider = vapi_data.dig('model', 'provider')
    model_name = vapi_data.dig('model', 'model') || vapi_data.dig('model', 'name')

    # Extract transcriber configuration
    transcriber_provider = vapi_data.dig('transcriber', 'provider')
    transcriber_language = vapi_data.dig('transcriber', 'language')

    # Extract phone number
    phone_number = vapi_data['phoneNumber'] || vapi_data['phone_number'] || vapi_data['phoneNumberId']

    {
      name: vapi_data['name'] || 'Imported Agent',
      phone_number: phone_number,
      first_message: first_message || 'Hello! How can I help you today?',
      system_prompt: system_prompt || 'You are a helpful voice assistant.',
      voice_provider: voice_provider || '11labs',
      voice_id: voice_id || '',
      model_provider: model_provider || 'openai',
      model_name: model_name || 'gpt-4o-mini',
      transcriber_provider: transcriber_provider || 'deepgram',
      transcriber_language: transcriber_language || 'en',
      vapi_agent_id: vapi_agent_id
    }
  end

  def extract_system_prompt_from_vapi(vapi_data)
    # Try to find system prompt in various locations
    if vapi_data.dig('model', 'messages').is_a?(Array)
      system_msg = vapi_data.dig('model', 'messages').find { |m| m['role'] == 'system' }
      return system_msg['content'] if system_msg

      # Fallback to first message
      return vapi_data.dig('model', 'messages', 0, 'content')
    end
    vapi_data.dig('model', 'systemPrompt') || vapi_data.dig('model', 'system_prompt')
  end
end
