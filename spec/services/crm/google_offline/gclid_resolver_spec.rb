require 'rails_helper'

RSpec.describe Crm::GoogleOffline::GclidResolver do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:pipeline) { account.crm_pipelines.create!(name: 'P', created_by: user, status: :active) }
  let(:stage) { account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'S', position: 0) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end

  def conversation_with(touches)
    create(:conversation, account: account, inbox: channel.inbox, additional_attributes: { 'campaign_touches' => touches })
  end

  it 'returns the most recent gclid touch across all card conversations' do
    primary = conversation_with([{ 'gclid' => 'PRIMARY', 'touched_at' => '2026-07-01T10:00:00Z' }])
    linked = conversation_with([
                                 { 'gclid' => 'OLDER', 'touched_at' => '2026-06-30T10:00:00Z' },
                                 { 'gclid' => 'LATEST', 'touched_at' => '2026-07-02T10:00:00Z' }
                               ])
    card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'C', currency: 'BRL', primary_conversation: primary)
    card.card_conversations.create!(account: account, conversation: linked)

    expect(described_class.resolve(card)).to eq('LATEST')
    expect(described_class.resolve_with_conversation(card).conversation_id).to eq(linked.id)
  end

  it 'ignores newer touches without gclid' do
    conversation = conversation_with([
                                       { 'gclid' => 'GOOGLE', 'touched_at' => '2026-07-01T10:00:00Z' },
                                       { 'fbclid' => 'META', 'touched_at' => '2026-07-02T10:00:00Z' }
                                     ])
    card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'C', currency: 'BRL', primary_conversation: conversation)

    expect(described_class.resolve(card)).to eq('GOOGLE')
  end

  it 'returns nil when no linked touch carries a gclid' do
    conversation = conversation_with([{ 'fbclid' => 'META', 'touched_at' => '2026-07-01T10:00:00Z' }])
    card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'C', currency: 'BRL', primary_conversation: conversation)

    expect(described_class.resolve(card)).to be_nil
  end
end
