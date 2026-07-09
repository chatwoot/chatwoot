require 'rails_helper'

# NOTE: the successful-delivery path (build_payload -> ConversionsApiClient ->
# record_result) is intentionally NOT covered here: Dispatch#dispatch calls
# `Crm::MetaCapi::PayloadBuilder.new(...).perform` and `ConversionsApiClient#send_event`,
# neither of which exists on the current collaborators (PayloadBuilder is a module
# exposing `.build`; the client exposes `#post_events` returning a Result with
# `ok`/`error`). Under verify_partial_doubles those methods cannot be stubbed, and a
# real run raises before persisting. This drift is reported as a blocking risk; once
# the interfaces are reconciled the accepted/error specs can be added.
RSpec.describe Crm::MetaCapi::DispatchJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:activity_id) { 42 }

  let(:campaign_attributes) { { 'campaign' => { 'ctwa_clid' => 'CLID123' } } }
  let(:pipeline_metadata) { { 'meta_sync' => { 'dataset_id' => 'DS123' } } }

  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox, additional_attributes: campaign_attributes) }
  let(:pipeline) { account.crm_pipelines.create!(name: 'P', created_by: user, status: :active, metadata: pipeline_metadata) }
  let(:stage) do
    account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'S', position: 0, metadata: { 'funnel_stage_type' => 'qualified' })
  end
  let(:card) do
    account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Card', currency: 'BRL',
                              value_cents: 50_000, primary_conversation: conversation)
  end

  let(:event_id) { "crm-#{card.id}-won-#{activity_id}" }

  def perform
    described_class.perform_now(account.id, card.id, activity_id, 'won')
  end

  it 'returns without a ledger row when the card no longer exists' do
    expect { described_class.perform_now(account.id, 0, activity_id, 'won') }
      .not_to change(Crm::MetaConversionEvent, :count)
  end

  describe 'skip paths' do
    context 'when the conversation carries no ctwa_clid' do
      let(:campaign_attributes) { {} }

      it 'marks the ledger row skipped and never calls the Meta client' do
        expect(Meta::ConversionsApiClient).not_to receive(:new)

        perform
        row = Crm::MetaConversionEvent.find_by(event_id: event_id)

        expect(row.status).to eq('skipped')
        expect(row.error_message).to eq('missing_ctwa_clid')
      end
    end

    context 'when the pipeline has no dataset_id' do
      let(:pipeline_metadata) { { 'meta_sync' => {} } }

      it 'marks the ledger row skipped for missing credentials' do
        perform
        row = Crm::MetaConversionEvent.find_by(event_id: event_id)

        expect(row.status).to eq('skipped')
        expect(row.error_message).to eq('missing_credentials')
      end

      it 'persists the deterministic card context on the skipped row' do
        perform
        row = Crm::MetaConversionEvent.find_by(event_id: event_id)

        expect(row).to have_attributes(
          account_id: account.id,
          card_id: card.id,
          pipeline_id: pipeline.id,
          event_type: 'won',
          source: 'live',
          funnel_stage_type: 'qualified',
          value_cents: 50_000,
          currency: 'BRL'
        )
      end
    end

    context 'when the linked channel exposes no access token' do
      # An API-channel inbox does not respond to #provider_config, so the token resolves to nil.
      let(:conversation) do
        inbox = create_crm_inbox(account: account)
        create(:conversation, account: account, inbox: inbox, additional_attributes: campaign_attributes)
      end

      it 'marks the ledger row skipped for missing credentials' do
        perform
        row = Crm::MetaConversionEvent.find_by(event_id: event_id)

        expect(row.status).to eq('skipped')
        expect(row.error_message).to eq('missing_credentials')
      end
    end
  end

  describe 'idempotency' do
    it 'short-circuits when a row for the same event_id is already accepted' do
      Crm::MetaConversionEvent.create!(account: account, card: card, event_id: event_id, event_type: 'won',
                                       status: :accepted, http_code: 200)
      expect(Meta::ConversionsApiClient).not_to receive(:new)

      expect { perform }.not_to change(Crm::MetaConversionEvent, :count)
      expect(Crm::MetaConversionEvent.find_by(event_id: event_id).status).to eq('accepted')
    end
  end

  describe 'security: token redaction' do
    let(:secret_token) { "EAAG#{'z' * 40}" }

    it 'never leaks a token-shaped secret into the log or the re-raised error' do
      allow(Crm::MetaConversionEvent).to receive(:find_or_initialize_by)
        .and_raise(StandardError.new("db down token=#{secret_token}"))
      logged = nil
      allow(Rails.logger).to receive(:error) { |message| logged = message }

      raised = nil
      begin
        perform
      rescue StandardError => e
        raised = e
      end

      expect(raised.class.name).to eq('Crm::MetaCapi::DispatchJob::DispatchError')
      expect(raised.message).not_to include(secret_token)
      expect(logged).to include('<REDACTED>')
      expect(logged).not_to include(secret_token)
    end
  end
end
