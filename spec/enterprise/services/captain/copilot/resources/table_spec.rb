require 'rails_helper'

RSpec.describe Captain::Copilot::Resources::Table do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }

  it 'has one resource per listed table, and lists only columns that exist, so a renamed column fails here instead of hiding' do
    tables = Captain::Copilot::Resources::Columns::TABLES
    resources = Captain::Copilot::Resources.all

    expect(resources.map { |resource| resource::MODEL.table_name }).to match_array(tables.keys)
    resources.each do |resource|
      entry = tables[resource::MODEL.table_name]
      expect(resource::MODEL.column_names).to include(*entry['columns'], *entry.fetch('json', []))
    end
  end

  it 'reads only the listed tables and columns' do
    names = Captain::Copilot::Resources.all.map { |resource| resource::NAME }
    agent_bots = Captain::Copilot::Resources.all.find { |resource| resource::NAME == 'agent_bots' }

    expect(names).to include('campaigns', 'reporting_events', 'inbox_members')
    expect(names).not_to include('notifications', 'custom_filters', 'webhooks', 'copilot_runs')
    expect(names.count('conversations')).to eq(1)
    expect(agent_bots.filter_schema['properties'].keys).to include('name')
    expect(agent_bots.filter_schema['properties'].keys).not_to include('secret', 'bot_config', 'outgoing_url')
  end

  it 'reads tables that belong to the account through another record, such as inbox members' do
    inbox = create(:inbox, account: account)
    create(:inbox_member, inbox: inbox, user: admin)
    create(:inbox_member)
    members = Captain::Copilot::Resources.build('inbox_members', account: account, user: admin)

    expect(members.matching(members.normalize({}), as_of: Time.current).pluck(:user_id)).to eq([admin.id])
    expect(Captain::Copilot::Resources.build('inboxes', account: account, user: admin).rows([inbox.id]).first[:label])
      .to eq("#{inbox.name} (ID #{inbox.id})")
  end

  it "shows the global macros and the administrator's own personal ones, as the macros page does" do
    other_admin = create(:user, :administrator, account: account)
    global = create(:macro, account: account, created_by: other_admin, visibility: :global)
    own = create(:macro, account: account, created_by: admin, visibility: :personal)
    create(:macro, account: account, created_by: other_admin, visibility: :personal)
    macros = Captain::Copilot::Resources.build('macros', account: account, user: admin)

    expect(macros.matching(macros.normalize({}), as_of: Time.current).pluck(:id)).to contain_exactly(global.id, own.id)
  end

  it 'shows the time zone of the record a row belongs to, such as the inbox of working hours' do
    inbox = create(:inbox, account: account, timezone: 'America/Los_Angeles')
    hours = Captain::Copilot::Resources.build('working_hours', account: account, user: admin)

    expect(hours.class::COLUMNS.last).to eq('Inbox time zone')
    expect(hours.rows([inbox.working_hours.first.id]).first[:values].last).to eq('America/Los_Angeles')
  end

  it 'refuses agents' do
    campaigns = Captain::Copilot::Resources.build('campaigns', account: account, user: create(:user, account: account))

    expect(campaigns.readable?).to be(false)
    expect { campaigns.matching(campaigns.normalize({}), as_of: Time.current) }.to raise_error(ArgumentError, /administrators/)
  end
end
