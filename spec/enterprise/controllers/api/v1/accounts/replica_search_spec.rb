require 'rails_helper'

RSpec.describe 'Replica search permissions', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:headers) { agent.create_new_auth_token }

  around do |example|
    with_modified_env POSTGRES_REPLICA_ENABLED: 'true' do
      example.run
    end
  end

  before do
    account.account_users.find_by!(user: agent).update!(custom_role: role)
    create(:inbox_member, inbox: inbox, user: agent)
    allow(ReadReplica::WriterStickiness).to receive(:sticky?).and_return(false)
    allow(ReadReplica::Health).to receive(:status).and_return(
      ReadReplica::Health::Status.new(healthy: true, lag_seconds: 0.5, checked_at: 0)
    )
  end

  it 'uses primary permissions for contact search' do
    contact = create(:contact, account: account, name: 'Test contact')
    permission_query_roles = []
    subscriber = lambda do |*args|
      permission_query_roles << ApplicationRecord.current_role if args.last[:name] == 'CustomRole Load'
    end

    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
      get "/api/v1/accounts/#{account.id}/search/contacts", headers: headers, params: { q: contact.name, per_page: 5 }
    end

    expect(response).to have_http_status(:ok)
    expect(permission_query_roles.uniq).to eq([:writing])
    expect(response.parsed_body.dig('payload', 'contacts')).to eq([])
  end

  it 'limits replica conversation search to conversations allowed by the primary permission context' do
    contact = create(:contact, account: account, name: 'Test contact')
    visible = create(:conversation, account: account, inbox: inbox, contact: contact, assignee: agent)
    create(:conversation, account: account, inbox: inbox, contact: contact)
    expect(Conversations::PermissionFilterService).to receive(:new).with(
      kind_of(ActiveRecord::Relation), agent, account,
      access_context: have_attributes(role: 'agent', permissions: include('conversation_participating_manage'))
    ).and_call_original

    get "/api/v1/accounts/#{account.id}/search/conversations", headers: headers, params: { q: contact.name, per_page: 5 }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('payload', 'conversations').pluck('id')).to eq([visible.display_id])
  end
end
