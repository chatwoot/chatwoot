class Api::V1::Accounts::AIAgentsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent, only: %i[show update destroy]

  def index
    @ai_agents = Current.account.ai_agents
    render json: @ai_agents
  end

  def show
    render json: @ai_agent
  end

  def create
    @ai_agent = Current.account.ai_agents.new(ai_agent_params)
    if @ai_agent.save
      render json: @ai_agent, status: :created
    else
      render json: @ai_agent.errors, status: :unprocessable_entity
    end
  end

  def update
    if @ai_agent.update(ai_agent_params)
      render json: @ai_agent
    else
      render json: @ai_agent.errors, status: :unprocessable_entity
    end
  end

  def avatar
    @ai_agent.avatar.purge if @ai_agent.avatar.attached?
    render json: @ai_agent
  end

  def destroy
    @ai_agent.destroy
    head :no_content
  end

  private

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
  end

  def ai_agent_params
    params.require(:ai_agent).permit(
      :name,
      :system_prompts,
      :welcoming_message,
      :routing_conditions,
      :control_flow_rules,
      :model_name,
      :history_limit,
      :context_limit,
      :message_await,
      :message_limit,
      :timezone
    )
  end
end
