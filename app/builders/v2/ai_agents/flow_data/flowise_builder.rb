class V2::AiAgents::FlowData::FlowiseBuilder < V2::AiAgents::FlowData::BaseBuilder
  include ChatFlowHelper

  def template
    @template ||= @templates.first
  end

  private

  def base_template
    {
      account_id: @account.id,
      type: 'flowise',
      enabled_agents: [],
      supervisor: {
        system_prompt: '',
        routing_system: []
      },
      agents_config: []
    }
  end
end
