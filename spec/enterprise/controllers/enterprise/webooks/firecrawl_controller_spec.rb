require 'rails_helper'

RSpec.describe 'Firecrawl Webhooks', type: :request do
  describe 'POST /enterprise/webhooks/firecrawl?assistant_id=:assistant_id&token=:token' do
    let!(:api_key) { create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: 'test_api_key_123') }
    let!(:account) { create(:account) }
    let!(:assistant) { create(:captain_assistant, account: account) }

    let(:payload_data) do
      {
        markdown: 'hello world',
        metadata: { ogUrl: 'https://example.com' }
      }
    end

    # Generate actual token using the helper
    let(:valid_token) do
      token_base = "#{api_key.value[-4..]}#{assistant.id}#{assistant.account_id}"
      Digest::SHA256.hexdigest(token_base)
    end

    context 'with valid token' do
      context 'with crawl.page event type' do
        let(:valid_params) do
          {
            type: 'crawl.page',
            data: [payload_data]
          }
        end

        it 'processes the webhook and returns success' do
          expect(Captain::Tools::FirecrawlParserJob).to receive(:perform_later)
            .with(
              assistant_id: assistant.id,
              payload: payload_data
            )

          post(
            "/enterprise/webhooks/firecrawl?assistant_id=#{assistant.id}&token=#{valid_token}",
            params: valid_params,
            as: :json
          )
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
        end
      end

      context 'with crawl.completed event type' do
        let(:valid_params) do
          {
            type: 'crawl.completed'
          }
        end

        it 'returns success without enqueuing job' do
          expect(Captain::Tools::FirecrawlParserJob).not_to receive(:perform_later)

          post("/enterprise/webhooks/firecrawl?assistant_id=#{assistant.id}&token=#{valid_token}",
               params: valid_params,
               as: :json)

          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
        end
      end
    end

    context 'with invalid token' do
      let(:invalid_params) do
        {
          type: 'crawl.page',
          data: [payload_data]
        }
      end

      it 'returns unauthorized status' do
        post("/enterprise/webhooks/firecrawl?assistant_id=#{assistant.id}&token=invalid_token",
             params: invalid_params,
             as: :json)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid assistant_id' do
      context 'with non-existent assistant_id' do
        it 'returns not found status' do
          post("/enterprise/webhooks/firecrawl?assistant_id=invalid_id&token=#{valid_token}",
               params: { type: 'crawl.page', data: [payload_data] },
               as: :json)

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'with nil assistant_id' do
        it 'returns not found status' do
          post("/enterprise/webhooks/firecrawl?token=#{valid_token}",
               params: { type: 'crawl.page', data: [payload_data] },
               as: :json)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when CAPTAIN_FIRECRAWL_API_KEY is not configured' do
      before do
        api_key.destroy
      end

      it 'returns unauthorized status' do
        post("/enterprise/webhooks/firecrawl?assistant_id=#{assistant.id}&token=#{valid_token}",
             params: { type: 'crawl.page', data: [payload_data] },
             as: :json)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
