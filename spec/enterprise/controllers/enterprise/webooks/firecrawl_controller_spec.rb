require 'rails_helper'

RSpec.describe 'Firecrawl Webhooks', type: :request do
  describe 'POST /enterprise/webhooks/firecrawl?topic_id=:topic_id&token=:token' do
    let!(:api_key) { create(:installation_config, name: 'AIAGENT_FIRECRAWL_API_KEY', value: 'test_api_key_123') }
    let!(:account) { create(:account) }
    let!(:topic) { create(:aiagent_topic, account: account) }

    let(:payload_data) do
      {
        markdown: 'hello world',
        metadata: { ogUrl: 'https://example.com' }
      }
    end

    # Generate actual token using the helper
    let(:valid_token) do
      token_base = "#{api_key.value[-4..]}#{topic.id}#{topic.account_id}"
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
          expect(Aiagent::Tools::FirecrawlParserJob).to receive(:perform_later)
            .with(
              topic_id: topic.id,
              payload: payload_data
            )

          post(
            "/enterprise/webhooks/firecrawl?topic_id=#{topic.id}&token=#{valid_token}",
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
          expect(Aiagent::Tools::FirecrawlParserJob).not_to receive(:perform_later)

          post("/enterprise/webhooks/firecrawl?topic_id=#{topic.id}&token=#{valid_token}",
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
        post("/enterprise/webhooks/firecrawl?topic_id=#{topic.id}&token=invalid_token",
             params: invalid_params,
             as: :json)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid topic_id' do
      context 'with non-existent topic_id' do
        it 'returns not found status' do
          post("/enterprise/webhooks/firecrawl?topic_id=invalid_id&token=#{valid_token}",
               params: { type: 'crawl.page', data: [payload_data] },
               as: :json)

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'with nil topic_id' do
        it 'returns not found status' do
          post("/enterprise/webhooks/firecrawl?token=#{valid_token}",
               params: { type: 'crawl.page', data: [payload_data] },
               as: :json)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when AIAGENT_FIRECRAWL_API_KEY is not configured' do
      before do
        api_key.destroy
      end

      it 'returns unauthorized status' do
        post("/enterprise/webhooks/firecrawl?topic_id=#{topic.id}&token=#{valid_token}",
             params: { type: 'crawl.page', data: [payload_data] },
             as: :json)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
