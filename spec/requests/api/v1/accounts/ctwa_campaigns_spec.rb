require 'rails_helper'

RSpec.describe 'CTWA campaigns API', type: :request do
  def create_conversation_with_touches(account:, inbox:, touches:)
    contact = account.contacts.create!(name: "Lead #{SecureRandom.hex(3)}", phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact)
    conversation.update!(
      additional_attributes: conversation.additional_attributes.merge(
        'campaign_touches' => touches,
        'campaign_source_ids' => touches.filter_map { |touch| touch['source_id'].presence }.uniq
      )
    )
    conversation
  end

  it 'returns unauthorized without credentials' do
    account, = create_account_and_user

    get "/api/v1/accounts/#{account.id}/ctwa_campaigns"

    expect(response).to have_http_status(:unauthorized)
  end

  it 'aggregates touches per ad with distinct conversation counts, freshest non-blank headline and last touch' do
    account, user = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [user])
    create_conversation_with_touches(
      account: account, inbox: inbox,
      touches: [{ 'source_id' => 'ad-a', 'headline' => 'Promo Julho', 'touched_at' => '2026-07-01T10:00:00Z' }]
    )
    create_conversation_with_touches(
      account: account, inbox: inbox,
      touches: [
        { 'source_id' => 'ad-a', 'headline' => '', 'touched_at' => '2026-07-02T10:00:00Z' },
        { 'source_id' => 'ad-b', 'headline' => 'Anúncio B', 'touched_at' => '2026-07-03T08:00:00Z' }
      ]
    )

    get "/api/v1/accounts/#{account.id}/ctwa_campaigns", headers: auth_headers(user)

    expect(response).to have_http_status(:success)
    payload = response.parsed_body['payload']
    expect(payload).to eq(
      [
        { 'source_id' => 'ad-a', 'headline' => 'Promo Julho', 'count' => 2, 'last_touch_at' => '2026-07-02T10:00:00Z' },
        { 'source_id' => 'ad-b', 'headline' => 'Anúncio B', 'count' => 1, 'last_touch_at' => '2026-07-03T08:00:00Z' }
      ]
    )
  end

  it 'never leaks another account campaigns and allows plain agents' do
    account, admin = create_account_and_user
    agent, = create_crm_agent(account: account)
    inbox = create_crm_inbox(account: account, members: [admin, agent])
    create_conversation_with_touches(
      account: account, inbox: inbox,
      touches: [{ 'source_id' => 'ad-mine', 'headline' => 'Meu anúncio', 'touched_at' => '2026-07-01T10:00:00Z' }]
    )
    other_account, other_user = create_account_and_user
    other_inbox = create_crm_inbox(account: other_account, members: [other_user])
    create_conversation_with_touches(
      account: other_account, inbox: other_inbox,
      touches: [{ 'source_id' => 'ad-other', 'headline' => 'Alheio', 'touched_at' => '2026-07-01T10:00:00Z' }]
    )

    get "/api/v1/accounts/#{account.id}/ctwa_campaigns", headers: auth_headers(agent)

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['payload'].pluck('source_id')).to eq(%w[ad-mine])
  end

  it 'hides campaigns from inboxes outside the agent visibility (admin still sees them)' do
    account, admin = create_account_and_user
    outsider, = create_crm_agent(account: account)
    restricted_inbox = create_crm_inbox(account: account, members: [admin])
    create_conversation_with_touches(
      account: account, inbox: restricted_inbox,
      touches: [{ 'source_id' => 'ad-restricted', 'headline' => 'Só do admin', 'touched_at' => '2026-07-01T10:00:00Z' }]
    )

    get "/api/v1/accounts/#{account.id}/ctwa_campaigns", headers: auth_headers(outsider)
    expect(response).to have_http_status(:success)
    expect(response.parsed_body['payload']).to eq([])

    get "/api/v1/accounts/#{account.id}/ctwa_campaigns", headers: auth_headers(admin)
    expect(response.parsed_body['payload'].pluck('source_id')).to eq(%w[ad-restricted])
  end

  it 'works with the CRM module disabled (endpoint lives outside the CRM gate)' do
    with_modified_env CRM_KANBAN_ENABLED: 'false' do
      account, user = create_account_and_user

      get "/api/v1/accounts/#{account.id}/ctwa_campaigns", headers: auth_headers(user)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to eq([])
    end
  end
end
