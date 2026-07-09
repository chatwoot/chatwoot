require 'rails_helper'

RSpec.describe Crm::MetaCapiListener do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:activity_id) { 77 }

  let(:pipeline) { account.crm_pipelines.create!(name: 'P', created_by: user, status: :active, metadata: pipeline_metadata) }
  let(:stage) { account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'S', position: 0) }
  let(:card) { account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'C', currency: 'BRL') }

  let(:pipeline_metadata) do
    { 'meta_sync' => { 'enabled' => true, 'events' => { 'won' => true, 'lost' => false, 'moved' => true } } }
  end

  before { clear_enqueued_jobs }

  def event_for(card_id)
    instance_double(Events::Base, data: { account_id: account.id, card_id: card_id, activity_id: activity_id })
  end

  it 'enqueues the dispatch job for a subscribed won event' do
    described_class.instance.crm_card_won(event_for(card.id))

    expect(Crm::MetaCapi::DispatchJob).to have_been_enqueued.with(account.id, card.id, activity_id, 'won')
  end

  it 'enqueues the dispatch job for a subscribed moved event' do
    described_class.instance.crm_card_moved(event_for(card.id))

    expect(Crm::MetaCapi::DispatchJob).to have_been_enqueued.with(account.id, card.id, activity_id, 'moved')
  end

  it 'does not enqueue for an event the pipeline did not subscribe to' do
    described_class.instance.crm_card_lost(event_for(card.id))

    expect(Crm::MetaCapi::DispatchJob).not_to have_been_enqueued
  end

  context 'when meta_sync is disabled' do
    let(:pipeline_metadata) { { 'meta_sync' => { 'enabled' => false, 'events' => { 'won' => true } } } }

    it 'does not enqueue even for a subscribed event' do
      described_class.instance.crm_card_won(event_for(card.id))

      expect(Crm::MetaCapi::DispatchJob).not_to have_been_enqueued
    end
  end

  context 'when the pipeline has no meta_sync config' do
    let(:pipeline_metadata) { {} }

    it 'does not enqueue' do
      described_class.instance.crm_card_won(event_for(card.id))

      expect(Crm::MetaCapi::DispatchJob).not_to have_been_enqueued
    end
  end

  it 'does not enqueue when the card cannot be found' do
    described_class.instance.crm_card_won(event_for(0))

    expect(Crm::MetaCapi::DispatchJob).not_to have_been_enqueued
  end
end
