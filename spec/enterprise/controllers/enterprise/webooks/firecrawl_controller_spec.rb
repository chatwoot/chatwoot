require 'rails_helper'

RSpec.describe 'Firecrawl Webhooks', type: :request do
  describe 'POST /enterprise/webhooks/firecrawl?assistant_id=:assistant_id' do
    let(:assistant_id) { 'asst_123' }
    let(:payload_data) do
      {
        'markdown' => 'hello world',
        'metadata' => {
          'ogUrl' => 'https://example.com'
        }
      }
    end

    context 'with crawl.page event type' do
      let(:valid_params) do
        {
          data: payload_data,
          type: 'crawl.page'
        }
      end

      it 'processes the webhook and returns success' do
        expect(Captain::Tools::FirecrawlParserJob).to(
          receive(:perform_later)
          .with(
            assistant_id: assistant_id,
            payload: payload_data
          )
        )

        post("/enterprise/webhooks/firecrawl?assistant_id=#{assistant_id}",
             params: valid_params,
             as: :json)

        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
      end
    end

    context 'with crawl.completed event type' do
      let(:valid_params) do
        { type: 'crawl.completed' }
      end

      it 'returns success without enqueuing job' do
        expect(Captain::Tools::FirecrawlParserJob).not_to receive(:perform_later)

        post("/enterprise/webhooks/firecrawl?assistant_id=#{assistant_id}",
             params: valid_params,
             as: :json)

        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
      end
    end
  end
end
