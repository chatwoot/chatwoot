class Vapi::AgentSyncService
  pattr_initialize [:account!]

  def perform
    return unless api_key_configured?

    begin
      vapi_agents = api_client.list_agents
      sync_agents_to_chatwoot(vapi_agents)
    rescue StandardError => e
      Rails.logger.error "Failed to sync Vapi agents: #{e.message}"
      { error: e.message }
    end
  end

  private

  def api_key_configured?
    ENV['VAPI_API_KEY'].present?
  end

  def api_client
    @api_client ||= Vapi::ApiClient.new
  end

  def sync_agents_to_chatwoot(vapi_agents)
    results = {
      synced: [],
      errors: []
    }

    vapi_agents.each do |agent_data|
      agent = find_or_create_vapi_agent(agent_data)
      results[:synced] << agent
    rescue StandardError => e
      results[:errors] << { agent: agent_data, error: e.message }
    end

    results
  end

  def find_or_create_vapi_agent(agent_data)
    vapi_agent_id = agent_data['id']
    existing_agent = account.vapi_agents.find_by(vapi_agent_id: vapi_agent_id)

    if existing_agent
      update_agent_data(existing_agent, agent_data)
    else
      create_new_agent(agent_data)
    end
  end

  def update_agent_data(agent, agent_data)
    agent.update!(
      name: agent_data['name'] || agent_data['firstName'],
      settings: agent_data.except('id', 'name', 'firstName')
    )
    agent
  end

  def create_new_agent(agent_data)
    # For new agents, we need to associate them with an inbox
    # We'll use the first available inbox in the account
    inbox = account.inboxes.first

    raise "No inboxes found in account #{account.id}. Please create an inbox first." if inbox.blank?

    VapiAgent.create!(
      account: account,
      inbox: inbox,
      vapi_agent_id: agent_data['id'],
      name: agent_data['name'] || agent_data['firstName'],
      settings: agent_data.except('id', 'name', 'firstName'),
      active: true
    )
  end
end

