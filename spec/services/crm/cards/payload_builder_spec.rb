require 'rails_helper'

RSpec.describe Crm::Cards::PayloadBuilder do
  around do |example|
    with_modified_env CRM_KANBAN_ENABLED: 'true' do
      example.run
    end
  end

  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:admin_account_user) { admin.account_users.find_by(account: account) }
  let(:inbox) { create_crm_inbox(account: account, members: [admin]) }

  def create_conversation(campaign_touches: nil, labels: nil, contact_labels: nil)
    contact = account.contacts.create!(name: "Lead #{SecureRandom.hex(3)}", phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    contact.add_labels(contact_labels) if contact_labels.present?
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact)
    if campaign_touches.present?
      conversation.update!(
        additional_attributes: conversation.additional_attributes.merge('campaign_touches' => campaign_touches)
      )
    end
    conversation.add_labels(labels) if labels.present?
    conversation
  end

  def create_card(conversation:)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_cards.create!(
      pipeline: pipeline, stage: stage, title: 'Lead CTWA',
      conversation_id: conversation.id, inbox_id: conversation.inbox_id, contact_id: conversation.contact_id
    )
  end

  def payload_for(card, user:, account_user:)
    described_class.new(card, user: user, account_user: account_user).perform
  end

  it 'exposes primary-conversation label titles and campaign touches aggregated across linked conversations' do
    account.labels.create!(title: 'vip')
    account.labels.create!(title: 'quente')
    primary = create_conversation(
      campaign_touches: [{ 'source' => 'meta_ctwa', 'source_id' => '111', 'headline' => 'Promo Julho',
                           'source_url' => 'https://fb.me/ad1', 'body' => 'nunca vaza', 'ctwa_clid' => 'clid-1',
                           'touched_at' => '2026-07-01T10:00:00Z' }],
      labels: %w[vip quente]
    )
    linked = create_conversation(
      campaign_touches: [{ 'source' => 'meta_ctwa', 'source_id' => '222', 'headline' => 'Anúncio Antigo',
                           'touched_at' => '2026-06-30T09:00:00Z' }]
    )
    card = create_card(conversation: primary)
    Crm::CardConversation.create!(account: account, card: card, conversation: linked)

    payload = payload_for(card, user: admin, account_user: admin_account_user)

    expect(payload[:labels]).to eq(primary.reload.cached_label_list_array)
    expect(payload[:labels]).to match_array(%w[vip quente])
    expect(payload[:campaigns]).to eq(
      [
        { source: 'meta_ctwa', source_id: '222', source_type: nil, headline: 'Anúncio Antigo', source_url: nil, touched_at: '2026-06-30T09:00:00Z',
          conversation_id: linked.id },
        { source: 'meta_ctwa', source_id: '111', source_type: nil, headline: 'Promo Julho', source_url: 'https://fb.me/ad1', touched_at: '2026-07-01T10:00:00Z',
          conversation_id: primary.id }
      ]
    )
  end

  it 'returns empty labels and campaigns when the primary conversation is not visible to the user' do
    outsider = create(:user, account: account, role: :agent)
    conversation = create_conversation(
      campaign_touches: [{ 'source' => 'meta_ctwa', 'source_id' => '111', 'headline' => 'Promo', 'touched_at' => '2026-07-01T10:00:00Z' }],
      labels: %w[vip]
    )
    card = create_card(conversation: conversation)

    payload = payload_for(card, user: outsider, account_user: outsider.account_users.find_by(account: account))

    expect(payload[:conversation_id]).to be_nil
    expect(payload[:labels]).to eq([])
    expect(payload[:campaigns]).to eq([])
  end

  it 'returns empty arrays for a standalone card' do
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Interno')

    payload = payload_for(card, user: admin, account_user: admin_account_user)

    expect(payload[:labels]).to eq([])
    expect(payload[:campaigns]).to eq([])
  end

  it 'exposes contact label titles separately from conversation labels and keeps them visible when the conversation is hidden' do
    outsider = create(:user, account: account, role: :agent)
    conversation = create_conversation(labels: %w[vip], contact_labels: %w[lote-01])
    card = create_card(conversation: conversation)

    visible_payload = payload_for(card, user: admin, account_user: admin_account_user)
    hidden_payload = payload_for(card, user: outsider, account_user: outsider.account_users.find_by(account: account))

    expect(visible_payload[:contact_labels]).to eq(%w[lote-01])
    expect(hidden_payload[:conversation_id]).to be_nil
    expect(hidden_payload[:contact_labels]).to eq(%w[lote-01])
  end
end
