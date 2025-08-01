class V2::AiAgents::FlowData::JangkauBuilder < V2::AiAgents::FlowData::BaseBuilder
  private

  def base_template
    {
      account_id: @account.id,
      type: 'multi-agent',
      enabled_agents: [],
      supervisor: {
        system_prompt: '',
        routing_system: []
      },
      agents_config: []
    }
  end
end
