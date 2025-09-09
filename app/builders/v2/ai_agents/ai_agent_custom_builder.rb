class V2::AiAgents::AiAgentCustomBuilder < V2::AiAgents::AiAgentBaseBuilder
  private

  def create
    ActiveRecord::Base.transaction do
      account.ai_agents.create!(ai_agent_params)
    end
  rescue StandardError => e
    Rails.logger.error("❌ Failed to create AI Agent: #{e.message}")
  end

  def update
    ActiveRecord::Base.transaction do
      ai_agent.update!(ai_agent_params)
    end

    ai_agent.as_create_json
  rescue StandardError => e
    Rails.logger.error("❌ Failed to update AI Agent: #{e.message}")
  end

  def ai_agent_params
    params.require(:ai_agent).permit(:name, :description, :agent_type, :chat_flow_id, display_flow_data: {})
  end
end
