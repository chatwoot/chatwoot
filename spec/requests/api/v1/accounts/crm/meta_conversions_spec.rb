require 'rails_helper'

# Read-only ledger surface consumed by the CRM UI (Lista column, card drawer badge,
# dashboard sync-health block).
RSpec.describe 'CRM meta_conversions API', type: :request do
  around do |example|
    previous_value = ENV.fetch('CRM_KANBAN_ENABLED', nil)
    ENV['CRM_KANBAN_ENABLED'] = 'true'
    example.run
  ensure
    if previous_value.nil?
      ENV.delete('CRM_KANBAN_ENABLED')
    else
      ENV['CRM_KANBAN_ENABLED'] = previous_value
    end
  end

  let(:account_and_user) { create_account_and_user }
  let(:account) { account_and_user.first }
  let(:user) { account_and_user.last }
  let(:pipeline) { account.crm_pipelines.create!(name: 'Funil', created_by: user, status: :active) }
  let(:stage) { account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'S', position: 0) }
  let(:card) { account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'C', currency: 'BRL') }

  def ledger(attrs)
    Crm::MetaConversionEvent.create!({ account: account, card: card, pipeline_id: pipeline.id }.merge(attrs))
  end

  describe 'GET /api/v1/accounts/:account_id/crm/meta_conversions' do
    it 'returns the latest event per requested card' do
      ledger(event_id: 'crm-a-moved-1', event_type: 'moved', status: :accepted, created_at: 2.days.ago)
      latest = ledger(event_id: 'crm-a-won-2', event_type: 'won', status: :accepted, http_code: 200,
                      created_at: 1.hour.ago)

      get "/api/v1/accounts/#{account.id}/crm/meta_conversions",
          params: { card_ids: [card.id] }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body['payload']
      expect(payload.size).to eq(1)
      expect(payload.first).to include('card_id' => card.id, 'event_type' => 'won',
                                       'status' => 'accepted', 'event_id' => latest.event_id)
    end

    it 'returns an empty payload when no card_ids are given' do
      get "/api/v1/accounts/#{account.id}/crm/meta_conversions", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['payload']).to eq([])
    end
  end

  describe 'GET /api/v1/accounts/:account_id/crm/meta_conversions/summary' do
    it 'aggregates status, event type, accepted revenue and last delivery' do
      ledger(event_id: 'crm-a-won-1', event_type: 'won', status: :accepted, value_cents: 30_000,
             sent_at: 1.hour.ago)
      ledger(event_id: 'crm-a-moved-2', event_type: 'moved', status: :skipped)

      get "/api/v1/accounts/#{account.id}/crm/meta_conversions/summary",
          params: { pipeline_id: pipeline.id }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body['payload']
      expect(payload['by_status']).to eq('accepted' => 1, 'skipped' => 1)
      expect(payload['by_event_type']).to eq('won' => 1, 'moved' => 1)
      expect(payload['accepted_count']).to eq(1)
      expect(payload['accepted_value_by_currency']).to eq('BRL' => 30_000)
      expect(payload['last_sent_at']).to be_present
    end
  end
end
