class Api::V1::Accounts::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :check_max_ai_agents, only: [:create]

  def index
    ai_agents = V2::AiAgents::AiAgentBuilder.new(Current.account, params).find_all_ai_agents
    render json: ai_agents, status: :ok
  end

  def show
    ai_agent = V2::AiAgents::AiAgentBuilder.new(Current.account, params).find_ai_agent
    render json: ai_agent, status: :ok
  end

  def create
    Rails.logger.info("🤖 AI Agent params: #{params}")
    builder = V2::AiAgents::AiAgentBuilder.new(Current.account, params)
    ai_agent = builder.build_and_create
    render json: ai_agent, status: :created
  rescue StandardError => e
    handle_error('Failed to create AI Agent', exception: e)
  end

  def update
    ai_agent = V2::AiAgents::AiAgentBuilder.new(Current.account, params).update
    render json: ai_agent, status: :ok
  rescue StandardError => e
    handle_error('Failed to update AI Agent', exception: e)
  end

  def destroy
    Rails.logger.info("🤖 AI Agent params: #{params}")
    builder = V2::AiAgents::AiAgentBuilder.new(Current.account, params)
    builder.destroy
    head :no_content
  rescue StandardError => e
    handle_error('Failed to delete AI Agent', exception: e)
  end

  def ai_agent_templates
    agent_templates = V2::AiAgents::AiAgentBuilder.new(Current.account, params).find_all_ai_agents_templates
    render json: agent_templates, status: :ok
  end

  private

  def check_max_ai_agents
    render_error('Maximum number of AI agents reached') unless Current.account.ai_agents.count < Current.account.current_max_ai_agents
  end

  def handle_error(message, status: :bad_request, exception: nil)
    Rails.logger.error("#{message}: #{exception&.message}")
    render_error(message, status)
  end

  def render_error(message, status = :bad_request)
    render json: { error: message }, status: status
  end
end
