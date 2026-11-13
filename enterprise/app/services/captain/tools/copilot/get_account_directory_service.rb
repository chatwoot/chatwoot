class Captain::Tools::Copilot::GetAccountDirectoryService < Captain::Tools::BaseTool
  SECTIONS = %w[agents inboxes teams labels campaigns].freeze
  MAX_PER_SECTION = 200

  def self.name
    'get_account_directory'
  end
  description 'List the account\'s agents, inboxes, teams, labels and campaigns with their IDs, as the agent can see them in the ' \
              "dashboard. Use it to find the ID of a person, inbox, team or label named in a request. Each section lists at most #{MAX_PER_SECTION}."
  parameters type: 'object', additionalProperties: false,
             properties: { sections: { type: 'array', items: { type: 'string', enum: SECTIONS }, description: 'Defaults to all' },
                           name: { type: 'string', description: 'Lists only the records whose name contains it' } }

  # Each section is a private method named after it, so only the listed sections can be called. A section with more
  # records than it lists is named in a note, so the model asks by name instead of saying a record does not exist.
  def execute(sections: SECTIONS, name: nil)
    unknown = sections - SECTIONS
    raise ArgumentError, "Unknown sections: #{unknown.join(', ')}. Available: #{SECTIONS.join(', ')}" if unknown.any?

    @name = name
    listed = sections.index_with { |section| send(section) }
    cut = listed.select { |_, records| records.is_a?(Array) && records.size > MAX_PER_SECTION }.keys
    listed = listed.transform_values { |records| records.is_a?(Array) ? records.first(MAX_PER_SECTION) : records }
    cut.any? ? listed.merge('note' => "#{cut.join(', ')} list the first #{MAX_PER_SECTION}. Pass name to find others.") : listed
  end

  private

  def agents
    named(account.account_users.joins(:user), User.arel_table[:name]).includes(:user).map do |member|
      { id: member.user_id, name: member.user.name, role: member.role }
    end
  end

  # Agents see the inboxes they are members of, as in the dashboard.
  def inboxes
    visible = administrator? ? account.inboxes : @user.inboxes.where(account_id: account.id)
    named(visible, Inbox.arel_table[:name]).map { |inbox| { id: inbox.id, name: inbox.name, channel: inbox.channel_type } }
  end

  def teams
    named(account.teams, Team.arel_table[:name]).map { |team| { id: team.id, name: team.name } }
  end

  def labels
    named(account.labels, Label.arel_table[:title]).map { |label| { id: label.id, name: label.title, description: label.description } }
  end

  # Campaigns are listed for administrators only, as in the dashboard.
  def campaigns
    return 'Only administrators can see campaigns' unless administrator?

    named(account.campaigns.includes(:inbox).order(created_at: :desc), Campaign.arel_table[:title]).map do |campaign|
      { id: campaign.display_id, title: campaign.title, type: campaign.campaign_type, status: campaign.campaign_status,
        enabled: campaign.enabled, inbox: campaign.inbox.name, scheduled_at: campaign.scheduled_at, created_at: campaign.created_at }
    end
  end

  # One more than a section lists, so execute can tell the section was cut.
  def named(records, column)
    records = records.where(column.matches("%#{ActiveRecord::Base.sanitize_sql_like(@name)}%")) if @name.present?
    records.limit(MAX_PER_SECTION + 1)
  end

  def administrator?
    account.account_users.find_by(user_id: @user.id)&.administrator?
  end

  def account
    @assistant.account
  end
end
