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

  def create_closed_card(attributes)
    card = attributes[:account].crm_cards.create!(
      pipeline: attributes[:pipeline],
      stage: attributes[:stage],
      primary_conversation: attributes[:conversation],
      contact: attributes[:conversation].contact,
      inbox: attributes[:conversation].inbox,
      title: "Deal #{SecureRandom.hex(3)}",
      value_cents: attributes[:value_cents],
      currency: attributes[:currency]
    )
    travel_to(attributes[:closed_at]) { card.update!(status: attributes[:status]) }
    card
  end

  def create_source_conversation(account:, inbox:, source_id:, source:, headline:)
    create_conversation_with_touches(
      account: account,
      inbox: inbox,
      touches: [{ 'source_id' => source_id, 'source' => source, 'headline' => headline, 'touched_at' => '2026-07-01T10:00:00Z' }]
    )
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
        { 'source_id' => 'ad-a', 'source' => nil, 'headline' => 'Promo Julho', 'count' => 2, 'last_touch_at' => '2026-07-02T10:00:00Z' },
        { 'source_id' => 'ad-b', 'source' => nil, 'headline' => 'Anúncio B', 'count' => 1, 'last_touch_at' => '2026-07-03T08:00:00Z' }
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

  it 'optionally includes won metrics scoped by pipeline and period' do
    account, user = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [user])
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    other_pipeline, other_stage = create_crm_pipeline(account: account, user: user, name: 'Outro funil')
    inside_range = Time.zone.parse('2026-07-04T10:00:00Z')
    outside_range = Time.zone.parse('2026-06-01T10:00:00Z')
    conversations = {
      'ad-a' => create_source_conversation(account: account, inbox: inbox, source_id: 'ad-a', source: 'meta_ctwa', headline: 'Meta A'),
      'gclid-1' => create_source_conversation(account: account, inbox: inbox, source_id: 'gclid-1', source: 'google_ads', headline: 'Google'),
      'old-a' => create_source_conversation(account: account, inbox: inbox, source_id: 'old-a', source: 'meta_ctwa', headline: 'Antigo'),
      'other-a' => create_source_conversation(account: account, inbox: inbox, source_id: 'other-a', source: 'tiktok_ads', headline: 'Outro')
    }
    [
      { source_id: 'ad-a', pipeline: pipeline, stage: stage, value_cents: 12_000, currency: 'BRL', status: :won, closed_at: inside_range },
      { source_id: 'gclid-1', pipeline: pipeline, stage: stage, value_cents: 30_000, currency: 'USD', status: :lost, closed_at: inside_range },
      { source_id: 'old-a', pipeline: pipeline, stage: stage, value_cents: 8_000, currency: 'BRL', status: :won, closed_at: outside_range },
      {
        source_id: 'other-a', pipeline: other_pipeline, stage: other_stage,
        value_cents: 5_000, currency: 'BRL', status: :won, closed_at: inside_range
      }
    ].each do |card_attrs|
      create_closed_card(
        card_attrs.merge(account: account, conversation: conversations[card_attrs[:source_id]])
      )
    end

    get "/api/v1/accounts/#{account.id}/ctwa_campaigns",
        params: {
          include_origin_metrics: true,
          pipeline_id: pipeline.id,
          since: '2026-07-01T00:00:00Z',
          until: '2026-07-31T23:59:59Z'
        },
        headers: auth_headers(user)

    expect(response).to have_http_status(:success)
    payload = response.parsed_body['payload'].index_by { |row| row['source_id'] }
    expect(payload['ad-a']).to include(
      'source' => 'meta_ctwa',
      'won_count' => 1,
      'won_value_by_currency' => [{ 'currency' => 'BRL', 'value_cents' => 12_000 }]
    )
    expect(payload['gclid-1']).to include('source' => 'google_ads', 'won_count' => 0, 'won_value_by_currency' => [])
    expect(payload['old-a']).to include('source' => 'meta_ctwa', 'won_count' => 0, 'won_value_by_currency' => [])
    expect(payload['other-a']).to include('source' => 'tiktok_ads', 'won_count' => 0, 'won_value_by_currency' => [])
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
