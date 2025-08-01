class Api::V1::Accounts::AiAgentsController < Api::V1::Accounts::BaseController
  include JsonHelper

  before_action :ai_agent, only: [:chat]
  # before_action :check_max_ai_agents, only: [:create]

  def index
    ai_agents = account.ai_agents.select(:id, :account_id, :name, :description)
    render json: ai_agents, status: :ok
  end

  def show
    render json: ai_agent.as_detailed_json, status: :ok
  end

  def create
    return render_expired_subscription unless Current.account.subscriptions.active.exists?

    ai_agent = ai_agent_builder.perform
    render json: ai_agent.as_create_json, status: :created
  rescue StandardError => e
    handle_error('Failed to create AI Agent', exception: e)
  end

  def update
    return render_expired_subscription unless Current.account.subscriptions.active.exists?

    ai_agent = ai_agent_builder(:update).perform
    render json: ai_agent, status: :ok
  rescue StandardError => e
    handle_error('Failed to update AI Agent', exception: e)
  end

  def destroy
    ai_agent_builder(:destroy).perform
    head :no_content
  rescue StandardError => e
    handle_error('Failed to delete AI Agent', exception: e)
  end

  def chat
    Captain::Llm::AssistantChatService.new(
      params[:question],
      params[:session_id],
      ai_agent.chat_flow_id,
      account.id
    ).generate_response.then do |response|
      if response.success?
        parsed_response = response.parsed_response
        json_data = extract_json_from_code_block(parsed_response['text'])
        render json: json_data, status: :ok
      else
        handle_error('Failed to generate AI response', status: :unprocessable_entity, exception: response)
      end
    end
  end

  def ai_agent_templates
    agent_templates = AiAgentTemplate.select(:id, :name, :template)
    render json: agent_templates, status: :ok
  end

  private

  def ai_agent_builder(action = :create)
    @ai_agent_builder ||= V2::AiAgents::AiAgentBuilder.new(Current.account, params, action)
  end

  def ai_agent
    @ai_agent ||= account.ai_agents.find(params[:id])
  end

  def account
    @account ||= Current.account
  end

  def check_max_ai_agents
    render_error('Maximum number of AI agents reached') unless account.ai_agents.count < account.current_max_ai_agents
  end

  def handle_error(message, status: :bad_request, exception: nil)
    Rails.logger.error("#{message}: #{exception&.message}")
    render_error(message, status)
  end

  def render_error(message, status = :bad_request)
    render json: { error: message, message: message }, status: status
  end
end
