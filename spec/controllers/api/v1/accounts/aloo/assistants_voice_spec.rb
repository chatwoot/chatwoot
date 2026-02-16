# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo Assistants Voice API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:assistant) { create(:aloo_assistant, :with_voice_features, account: account) }

  describe 'GET /api/v1/accounts/:account_id/aloo/assistants/:id/voices' do
    let(:voices_response) do
      [
        { 'voice_id' => 'voice1', 'name' => 'Sarah', 'category' => 'premade', 'description' => 'Friendly voice' },
        { 'voice_id' => 'voice2', 'name' => 'Adam', 'category' => 'premade', 'description' => 'Professional voice' }
      ]
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/voices"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'with ElevenLabs API key configured' do
        before do
          stub_request(:get, 'https://api.elevenlabs.io/v1/voices')
            .with(headers: { 'xi-api-key' => 'test-api-key' })
            .to_return(status: 200, body: { 'voices' => voices_response }.to_json)

          account.update!(custom_attributes: { 'elevenlabs_api_key' => 'test-api-key' })
        end

        it 'returns list of available voices' do
          get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/voices",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          data = response.parsed_body
          expect(data['voices'].length).to eq(2)
          expect(data['voices'].first['voice_id']).to eq('voice1')
          expect(data['voices'].first['name']).to eq('Sarah')
        end
      end

      context 'without ElevenLabs API key configured' do
        before do
          # Ensure no API key is found
          allow(InstallationConfig).to receive(:find_by).and_return(nil)
        end

        it 'returns service unavailable with error message' do
          with_modified_env ELEVENLABS_API_KEY: nil do
            get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/voices",
                headers: admin.create_new_auth_token,
                as: :json

            expect(response).to have_http_status(:service_unavailable)
            expect(response.parsed_body['error']).to include('not configured')
          end
        end
      end

      context 'when ElevenLabs API returns error' do
        before do
          account.update!(custom_attributes: { 'elevenlabs_api_key' => 'invalid-key' })
          stub_request(:get, 'https://api.elevenlabs.io/v1/voices')
            .to_return(status: 401, body: '{"detail": "Invalid API key"}')
        end

        it 'returns service unavailable with error message' do
          get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/voices",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:service_unavailable)
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/aloo/assistants/:id/preview_voice' do
    let(:audio_binary) { 'fake-mp3-binary-data' }
    let(:ogg_path) { '/tmp/voice_preview.ogg' }
    let(:synthesis_result) do
      {
        success: true,
        audio_path: ogg_path,
        audio_data: audio_binary,
        content_type: 'audio/ogg',
        format: 'ogg'
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/preview_voice"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        File.write(ogg_path, audio_binary)
      end

      after do
        FileUtils.rm_f(ogg_path)
      end

      context 'with valid parameters' do
        before do
          allow_any_instance_of(Aloo::VoiceSynthesisService).to receive(:perform)
            .and_return(synthesis_result)
        end

        it 'returns audio data' do
          post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/preview_voice",
               headers: admin.create_new_auth_token,
               params: { voice_id: 'test-voice-id', text: 'Hello world' },
               as: :json

          expect(response).to have_http_status(:success)
          expect(response.content_type).to include('audio/ogg')
        end

        it 'uses default text when not provided' do
          expect_any_instance_of(Aloo::VoiceSynthesisService).to receive(:perform)
            .and_return(synthesis_result)

          post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/preview_voice",
               headers: admin.create_new_auth_token,
               params: { voice_id: 'test-voice-id' },
               as: :json

          expect(response).to have_http_status(:success)
        end
      end

      context 'without voice_id parameter' do
        it 'uses assistant configured voice_id' do
          allow_any_instance_of(Aloo::VoiceSynthesisService).to receive(:perform)
            .and_return(synthesis_result)

          post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/preview_voice",
               headers: admin.create_new_auth_token,
               params: { text: 'Hello' },
               as: :json

          expect(response).to have_http_status(:success)
        end

        context 'when assistant has no voice configured' do
          let(:assistant) { create(:aloo_assistant, account: account) }

          it 'returns unprocessable entity' do
            post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/preview_voice",
                 headers: admin.create_new_auth_token,
                 params: { text: 'Hello' },
                 as: :json

            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.parsed_body['error']).to eq('voice_id is required')
          end
        end
      end

      context 'when synthesis fails' do
        before do
          allow_any_instance_of(Aloo::VoiceSynthesisService).to receive(:perform)
            .and_return({ success: false, error: 'API error' })
        end

        it 'returns unprocessable entity' do
          post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/preview_voice",
               headers: admin.create_new_auth_token,
               params: { voice_id: 'test-voice-id' },
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to eq('API error')
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/aloo/assistants/:id/voice_usage' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/voice_usage"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        create(:aloo_voice_usage_record, :transcription,
               account: account,
               assistant: assistant,
               audio_duration_seconds: 60)
        create(:aloo_voice_usage_record, :synthesis,
               account: account,
               assistant: assistant,
               characters_used: 500)
        create(:aloo_voice_usage_record, :failed,
               account: account,
               assistant: assistant)
      end

      it 'returns usage statistics' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/voice_usage",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body

        expect(data['transcription']['count']).to eq(1)
        expect(data['synthesis']['count']).to eq(1)
        expect(data['failed_operations']).to eq(1)
        expect(data).to have_key('period')
        expect(data).to have_key('total_estimated_cost')
      end

      it 'accepts custom date range' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/voice_usage",
            headers: admin.create_new_auth_token,
            params: { period_start: 1.week.ago.iso8601, period_end: Time.current.iso8601 },
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
