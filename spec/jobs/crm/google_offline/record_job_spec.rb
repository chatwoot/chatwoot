require 'rails_helper'

RSpec.describe Crm::GoogleOffline::RecordJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:pipeline_metadata) do
    {
      'google_sync' => {
        'conversion_names' => { 'qualified' => 'Lead qualificado' }
      }
    }
  end
  let(:pipeline) { account.crm_pipelines.create!(name: 'P', created_by: user, status: :active, metadata: pipeline_metadata) }
  let(:stage) do
    account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'Qualificação', position: 0,
                                        metadata: { 'funnel_stage_type' => 'qualified' })
  end
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:touches) { [{ 'gclid' => 'GCLID-123', 'touched_at' => '2026-07-01T10:00:00Z' }] }
  let(:conversation) do
    create(:conversation, account: account, inbox: channel.inbox, additional_attributes: { 'campaign_touches' => touches })
  end
  let(:card) do
    account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'C', currency: 'BRL', value_cents: 50_000,
                              primary_conversation: conversation)
  end
  let(:activity) { Crm::Activity.create!(account: account, card: card, event_type: 'won') }

  def perform(event_type = 'won', target_activity = activity)
    described_class.perform_now(account.id, card.id, target_activity.id, event_type)
  end

  it 'records a ready won conversion with attribution, value and configured stage name' do
    perform

    event = Crm::GoogleConversionEvent.find_by!(event_id: "crm-#{card.id}-won-#{activity.id}")
    expect(event).to have_attributes(
      account_id: account.id,
      card_id: card.id,
      conversation_id: conversation.id,
      activity_id: activity.id,
      gclid: 'GCLID-123',
      conversion_name: 'Lead qualificado',
      conversion_time: activity.created_at,
      value_cents: 50_000,
      currency: 'BRL',
      status: 'ready',
      skip_reason: nil
    )
  end

  it 'uses the won default when the current stage type has no configured name' do
    pipeline.update!(metadata: { 'google_sync' => { 'conversion_names' => {} } })

    perform

    expect(Crm::GoogleConversionEvent.last.conversion_name).to eq('Venda WhatsApp')
  end

  it 'marks the conversion skipped when no gclid can be resolved' do
    conversation.update!(additional_attributes: { 'campaign_touches' => [] })

    perform

    expect(Crm::GoogleConversionEvent.last).to have_attributes(status: 'skipped', skip_reason: 'missing_gclid', gclid: nil)
  end

  it 'uses the moved destination stage name and does not record value' do
    destination = account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'Negociação', position: 1,
                                                      metadata: { 'funnel_stage_type' => 'negotiation' })
    move = Crm::Activity.create!(account: account, card: card, event_type: 'move', payload: { 'to_stage_id' => destination.id })

    perform('moved', move)

    expect(Crm::GoogleConversionEvent.last).to have_attributes(
      conversion_name: 'Negociação',
      conversion_time: move.created_at,
      value_cents: nil,
      currency: nil
    )
  end

  it 'deduplicates repeated jobs with the same card, event type and activity' do
    expect do
      perform
      perform
    end.to change(Crm::GoogleConversionEvent, :count).by(1)
  end

  it 'treats a concurrent unique-index loss as an already claimed event' do
    allow(Crm::GoogleConversionEvent).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)

    expect { perform }.not_to raise_error
  end

  it 'returns without recording when the card no longer exists' do
    expect do
      described_class.perform_now(account.id, 0, activity.id, 'won')
    end.not_to change(Crm::GoogleConversionEvent, :count)
  end
end
