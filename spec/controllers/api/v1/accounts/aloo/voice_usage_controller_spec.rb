# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo Voice Usage API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:assistant) { create(:aloo_assistant, :with_voice_features, account: account) }
  let(:tenant_id) { account.id.to_s }

  def create_execution(agent_type:, status: 'success', started_at: Time.current, cost: 0.001, duration_ms: 500, metadata: {})
    RubyLLM::Agents::Execution.create!(
      agent_type: agent_type,
      model_id: agent_type.include?('Transcriber') ? 'whisper-1' : 'eleven_v3',
      status: status,
      started_at: started_at,
      completed_at: started_at + (duration_ms / 1000.0).seconds,
      duration_ms: duration_ms,
      total_cost: cost,
      tenant_id: tenant_id,
      metadata: metadata
    )
  end

  describe 'GET /api/v1/accounts/:account_id/aloo/voice_usage (show)' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        create_execution(agent_type: 'Audio::AlooTranscriber', duration_ms: 120_000,
                         metadata: { 'aloo_assistant_id' => assistant.id.to_s })
        create_execution(agent_type: 'Audio::AlooTranscriber', duration_ms: 60_000,
                         metadata: { 'aloo_assistant_id' => assistant.id.to_s })
        create_execution(agent_type: 'Audio::AlooSpeaker', cost: 0.03,
                         metadata: { 'aloo_assistant_id' => assistant.id.to_s })
        create_execution(agent_type: 'Audio::AlooTranscriber', status: 'error',
                         metadata: { 'aloo_assistant_id' => assistant.id.to_s })
      end

      it 'returns account-wide voice usage statistics' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body

        expect(data['transcription']['count']).to eq(2)
        expect(data['synthesis']['count']).to eq(1)
        expect(data['failed_operations']).to eq(1)
        expect(data).to have_key('by_assistant')
        expect(data).to have_key('daily_breakdown')
      end

      it 'includes assistant breakdown' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage",
            headers: admin.create_new_auth_token,
            as: :json

        data = response.parsed_body
        assistant_data = data['by_assistant'].find { |a| a['id'] == assistant.id }

        expect(assistant_data).to be_present
        expect(assistant_data['transcription_count']).to eq(2)
        expect(assistant_data['synthesis_count']).to eq(1)
      end

      it 'accepts custom date range' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage",
            headers: admin.create_new_auth_token,
            params: {
              period_start: 1.month.ago.iso8601,
              period_end: Time.current.iso8601
            },
            as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body
        expect(data['period']['start']).to be_present
        expect(data['period']['end']).to be_present
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/aloo/voice_usage/summary' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage/summary"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        # Current month records
        create_execution(agent_type: 'Audio::AlooTranscriber',
                         metadata: { 'aloo_assistant_id' => assistant.id.to_s })
        create_execution(agent_type: 'Audio::AlooSpeaker', cost: 0.015,
                         metadata: { 'aloo_assistant_id' => assistant.id.to_s })

        # Last month records
        create_execution(agent_type: 'Audio::AlooTranscriber', started_at: 1.month.ago,
                         metadata: { 'aloo_assistant_id' => assistant.id.to_s })
        create_execution(agent_type: 'Audio::AlooSpeaker', cost: 0.03, started_at: 1.month.ago,
                         metadata: { 'aloo_assistant_id' => assistant.id.to_s })
      end

      it 'returns summary with current and last month comparison' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage/summary",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body

        expect(data['current_month']['transcription_count']).to eq(1)
        expect(data['current_month']['synthesis_count']).to eq(1)
        expect(data['last_month']['transcription_count']).to eq(1)
        expect(data['last_month']['synthesis_count']).to eq(1)
      end

      it 'includes quota information' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage/summary",
            headers: admin.create_new_auth_token,
            as: :json

        data = response.parsed_body

        expect(data['quota']).to have_key('daily_limit')
        expect(data['quota']).to have_key('used_today')
        expect(data['quota']).to have_key('remaining')
        expect(data['quota']).to have_key('percentage_used')
      end
    end
  end
end
