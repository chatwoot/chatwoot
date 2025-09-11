class V2::AiAgents::AiAgentBaseBuilder
  attr_reader :account, :params

  def initialize(account, params, action)
    @account = account
    @params = params
    @action = action
  end

  def perform
    case @action
    when :create
      create
    when :update
      update
    when :destroy
      destroy
    else
      raise ArgumentError, "Unknown action: #{@action}"
    end
  rescue StandardError => e
    Rails.logger.error("❌ Error in AI Agent Builder: #{e.message}")
    raise e
  end

  private

  def template_id
    params[:template_id].presence || ai_agent.template_id
  end

  def template_ids
    params[:template_ids].presence || ai_agent.template_id
  end

  def ai_agent_template
    @ai_agent_template ||= AiAgentTemplate.find_by(id: template_id)
  end

  def ai_agent_templates
    @ai_agent_templates ||= AiAgentTemplate.where(id: template_ids)
  end

  def ai_agent
    @ai_agent ||= account.ai_agents.find(params[:id])
  end

  def production_environment?
    ENV.fetch('RAILS_ENV', nil) == 'production'
  end
end
