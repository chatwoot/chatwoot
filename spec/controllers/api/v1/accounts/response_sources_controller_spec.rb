require 'rails_helper'

RSpec.describe 'Response Sources API', type: :request do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/response_sources/parse' do
    let(:valid_params) do
      {
        link: 'http://test.test'
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/response_sources/parse", params: valid_params }.not_to change(Label, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns links in the webpage' do
        crawler = double
        allow(PageCrawlerService).to receive(:new).and_return(crawler)
        allow(crawler).to receive(:get_links).and_return(['http://test.test'])

        post "/api/v1/accounts/#{account.id}/response_sources/parse", headers: admin.create_new_auth_token,
                                                                      params: valid_params
        expect(response).to have_http_status(:success)
        expect(response.parsed_body['links']).to eq(['http://test.test'])
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/response_sources' do
    let(:valid_params) do
      {
        response_source: {
          name: 'Test',
          source_link: 'http://test.test',
          inbox_id: inbox.id,
          response_documents_attributes: [
            { document_link: 'http://test1.test' },
            { document_link: 'http://test2.test' }
          ]
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/response_sources", params: valid_params }.not_to change(Label, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'creates the response sources and documents' do
        expect do
          post "/api/v1/accounts/#{account.id}/response_sources", headers: admin.create_new_auth_token,
                                                                  params: valid_params
        end.to change(ResponseSource, :count).by(1)

        expect(ResponseDocument.count).to eq(2)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
