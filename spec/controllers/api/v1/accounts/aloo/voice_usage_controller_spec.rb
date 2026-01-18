# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo Voice Usage API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:assistant) { create(:aloo_assistant, :with_voice_features, account: account) }

  # NOTE: voice_usage is a singular resource, so we test against /aloo/voice_usage (show action)
  # The controller#index action maps to the show route
  describe 'GET /api/v1/accounts/:account_id/aloo/voice_usage (show)' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        create(:aloo_voice_usage_record, :transcription, account: account, assistant: assistant, audio_duration_seconds: 120)
        create(:aloo_voice_usage_record, :transcription, account: account, assistant: assistant, audio_duration_seconds: 60)
        create(:aloo_voice_usage_record, :synthesis, account: account, assistant: assistant, characters_used: 1000)
        create(:aloo_voice_usage_record, :failed, account: account, assistant: assistant)
      end

      it 'returns account-wide voice usage statistics' do
        get "/api/v1/accounts/#{account.id}/aloo/voice_usage",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body

        expect(data['transcription']['count']).to eq(2)
        expect(data['transcription']['total_duration_seconds']).to eq(180)
        expect(data['synthesis']['count']).to eq(1)
        expect(data['synthesis']['total_characters']).to eq(1000)
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
        create(:aloo_voice_usage_record, :transcription, account: account, assistant: assistant)
        create(:aloo_voice_usage_record, :synthesis, account: account, assistant: assistant, characters_used: 500)

        # Last month records
        create(:aloo_voice_usage_record, :transcription, account: account, assistant: assistant, created_at: 1.month.ago)
        create(:aloo_voice_usage_record, :synthesis, account: account, assistant: assistant, characters_used: 1000, created_at: 1.month.ago)
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
