require 'rails_helper'

# Guards the dispatch gate: CRM card lifecycle events reach the dispatcher when an
# account webhook subscribes them OR when a pipeline opted into Meta CAPI sync —
# without the second branch the Meta listener silently never fires.
RSpec.describe Crm::Webhooks::Emitter do
  # crm.card.* is only a valid webhook subscription when the CRM is enabled.
  around { |example| with_modified_env(CRM_KANBAN_ENABLED: 'true') { example.run } }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:pipeline) do
    account.crm_pipelines.create!(name: 'P', created_by: user, status: :active, metadata: pipeline_metadata)
  end
  let(:pipeline_metadata) { {} }

  def emit(event_type: 'won')
    described_class.emit(
      account_id: account.id, card_id: 1, activity_id: 2, event_type: event_type, changed_attributes: nil
    )
  end

  # The dispatcher also receives unrelated model-lifecycle events from the test
  # setup, so every assertion targets the crm.card.* event explicitly.
  before { allow(Rails.configuration.dispatcher).to receive(:dispatch) }

  def expect_no_card_dispatch(event)
    expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(event, any_args)
  end

  context 'when nothing subscribes the event' do
    it 'does not dispatch' do
      pipeline
      emit

      expect_no_card_dispatch('crm.card.won')
    end
  end

  context 'when an account webhook subscribes the event' do
    it 'dispatches' do
      create(:webhook, account: account, webhook_type: :account_type, subscriptions: ['crm.card.won'])
      emit

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with('crm.card.won', anything, hash_including(account_id: account.id, activity_id: 2))
    end
  end

  context 'when a pipeline opted into Meta sync for the event' do
    let(:pipeline_metadata) { { 'meta_sync' => { 'enabled' => true, 'events' => { 'won' => true } } } }

    it 'dispatches even without any account webhook' do
      pipeline
      emit

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with('crm.card.won', anything, hash_including(account_id: account.id))
    end

    it 'does not dispatch an event the pipeline did not subscribe' do
      pipeline
      emit(event_type: 'lost')

      expect_no_card_dispatch('crm.card.lost')
    end
  end

  context 'when Meta sync is configured but disabled' do
    let(:pipeline_metadata) { { 'meta_sync' => { 'enabled' => false, 'events' => { 'won' => true } } } }

    it 'does not dispatch' do
      pipeline
      emit

      expect_no_card_dispatch('crm.card.won')
    end
  end
end
