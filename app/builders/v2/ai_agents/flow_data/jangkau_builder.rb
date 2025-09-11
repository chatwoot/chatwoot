class V2::AiAgents::FlowData::JangkauBuilder < V2::AiAgents::FlowData::BaseBuilder
  private

  def base_template
    {
      account_id: @account.id.to_s,
      bot_name: '',
      type: 'multi-agent',
      enabled_agents: [],
      agents_config: []
    }
  end
end
