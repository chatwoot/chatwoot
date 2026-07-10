require 'rails_helper'

RSpec.describe Crm::GoogleOfflineListener do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:activity_id) { 77 }
  let(:pipeline_metadata) do
    {
      'google_sync' => {
        'enabled' => true,
        'events' => { 'won' => true, 'lost' => false, 'moved' => true },
        'conversion_names' => {}
      }
    }
  end
  let(:pipeline) { account.crm_pipelines.create!(name: 'P', created_by: user, status: :active, metadata: pipeline_metadata) }
  let(:stage) { account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'S', position: 0) }
  let(:card) { account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'C', currency: 'BRL') }

  before { clear_enqueued_jobs }

  def event_for(card_id = card.id)
    instance_double(Events::Base, data: { account_id: account.id, card_id: card_id, activity_id: activity_id })
  end

  it 'enqueues subscribed won and moved events' do
    described_class.instance.crm_card_won(event_for)
    described_class.instance.crm_card_moved(event_for)

    expect(Crm::GoogleOffline::RecordJob).to have_been_enqueued.with(account.id, card.id, activity_id, 'won')
    expect(Crm::GoogleOffline::RecordJob).to have_been_enqueued.with(account.id, card.id, activity_id, 'moved')
  end

  it 'does not enqueue an unsubscribed event' do
    described_class.instance.crm_card_lost(event_for)

    expect(Crm::GoogleOffline::RecordJob).not_to have_been_enqueued
  end

  context 'when google_sync is disabled' do
    let(:pipeline_metadata) { { 'google_sync' => { 'enabled' => false, 'events' => { 'won' => true } } } }

    it 'does not enqueue' do
      described_class.instance.crm_card_won(event_for)

      expect(Crm::GoogleOffline::RecordJob).not_to have_been_enqueued
    end
  end

  it 'does not enqueue when the card does not exist' do
    described_class.instance.crm_card_won(event_for(0))

    expect(Crm::GoogleOffline::RecordJob).not_to have_been_enqueued
  end

  it 'is registered in the async dispatcher beside the Meta listener' do
    listeners = AsyncDispatcher.new.listeners

    expect(listeners).to include(Crm::MetaCapiListener.instance, described_class.instance)
  end
end
