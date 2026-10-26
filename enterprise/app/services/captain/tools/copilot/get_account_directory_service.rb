class Captain::Tools::Copilot::GetAccountDirectoryService < Captain::Tools::BaseTool
  SECTIONS = %w[agents inboxes teams labels campaigns].freeze
  MAX_PER_SECTION = 200

  def self.name
    'get_account_directory'
  end
  description 'List the account\'s agents, inboxes, teams, labels and campaigns with their IDs, as the agent can see them in the ' \
              'dashboard. Use it to find the ID of a person, inbox, team or label named in a request.'
  parameters type: 'object', additionalProperties: false,
             properties: { sections: { type: 'array', items: { type: 'string', enum: SECTIONS }, description: 'Defaults to all' } }

  # Each section is a private method named after it, so only the listed sections can be called.
  def execute(sections: SECTIONS)
    unknown = sections - SECTIONS
    raise ArgumentError, "Unknown sections: #{unknown.join(', ')}. Available: #{SECTIONS.join(', ')}" if unknown.any?

    sections.index_with { |section| send(section) }
  end

  private

  def agents
    account.account_users.includes(:user).limit(MAX_PER_SECTION).map { |member| { id: member.user_id, name: member.user.name, role: member.role } }
  end

  # Agents see the inboxes they are members of, as in the dashboard.
  def inboxes
    visible = administrator? ? account.inboxes : @user.inboxes.where(account_id: account.id)
    visible.limit(MAX_PER_SECTION).map { |inbox| { id: inbox.id, name: inbox.name, channel: inbox.channel_type } }
  end

  def teams
    account.teams.limit(MAX_PER_SECTION).map { |team| { id: team.id, name: team.name } }
  end

  def labels
    account.labels.limit(MAX_PER_SECTION).map { |label| { id: label.id, name: label.title, description: label.description } }
  end

  # Campaigns are listed for administrators only, as in the dashboard.
  def campaigns
    return 'Only administrators can see campaigns' unless administrator?

    account.campaigns.includes(:inbox).order(created_at: :desc).limit(MAX_PER_SECTION).map do |campaign|
      { id: campaign.display_id, title: campaign.title, type: campaign.campaign_type, status: campaign.campaign_status,
        enabled: campaign.enabled, inbox: campaign.inbox.name, scheduled_at: campaign.scheduled_at, created_at: campaign.created_at }
    end
  end

  def administrator?
    account.account_users.find_by(user_id: @user.id)&.administrator?
  end

  def account
    @assistant.account
  end
end
