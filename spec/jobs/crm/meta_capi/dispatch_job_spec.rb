require 'rails_helper'

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

  describe 'delivery' do
    let(:client) { instance_double(Meta::ConversionsApiClient) }

    before { allow(Meta::ConversionsApiClient).to receive(:new).and_return(client) }

    it 'posts the built event and records an accepted ledger row' do
      allow(client).to receive(:post_events)
        .and_return(Meta::ConversionsApiClient::Result.new(ok: true, http_code: 200, body: 'ok', error: nil))

      perform
      row = Crm::MetaConversionEvent.find_by(event_id: event_id)

      expect(client).to have_received(:post_events) do |events|
        payload = events.first
        expect(payload['event_name']).to eq('Purchase')
        expect(payload['event_id']).to eq(event_id)
        expect(payload['user_data']).to include('ctwa_clid' => 'CLID123')
      end
      expect(row.status).to eq('accepted')
      expect(row.http_code).to eq(200)
      expect(row.sent_at).to be_present
    end

    it 'records an error row and re-raises when Meta rejects the event' do
      allow(client).to receive(:post_events)
        .and_return(Meta::ConversionsApiClient::Result.new(ok: false, http_code: 400, body: 'bad', error: 'invalid dataset'))

      expect { perform }.to raise_error(Crm::MetaCapi::DispatchJob::DispatchError)
      row = Crm::MetaConversionEvent.find_by(event_id: event_id)

      expect(row.status).to eq('error')
      expect(row.http_code).to eq(400)
      expect(row.error_message).to eq('invalid dataset')
    end
  end

  describe 'security: token redaction' do
    let(:secret_token) { "EAAG#{'z' * 40}" }

    it 'never leaks a token-shaped secret into the log or the re-raised error' do
      allow(Crm::MetaConversionEvent).to receive(:find_or_initialize_by)
        .and_raise(StandardError.new("db down token=#{secret_token}"))
      # Replace Rails.logger wholesale so the job's Rails.logger.error writes to a buffer we
      # own, regardless of the app's custom logger proxy (identity-based stubs miss it).
      io = StringIO.new
      allow(Rails).to receive(:logger).and_return(ActiveSupport::Logger.new(io))

      raised = nil
      begin
        perform
      rescue StandardError => e
        raised = e
      end

      expect(raised.class.name).to eq('Crm::MetaCapi::DispatchJob::DispatchError')
      expect(raised.message).not_to include(secret_token)
      expect(io.string).to include('<REDACTED>')
      expect(io.string).not_to include(secret_token)
    end
  end
end
