require 'rails_helper'

RSpec.describe 'Response Sources API', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }

  before do
    skip_unless_response_bot_enabled_test_environment
  end

  describe 'POST /api/v1/accounts/{account.id}/response_sources/parse' do
    let(:valid_params) do
      {
        link: 'http://test.test'
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/response_sources/parse", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns links in the webpage' do
        crawler = double
        allow(PageCrawlerService).to receive(:new).and_return(crawler)
        allow(crawler).to receive(:page_links).and_return(['http://test.test'])

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
          response_documents_attributes: [
            { document_link: 'http://test1.test' },
            { document_link: 'http://test2.test' }
          ]
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/response_sources", params: valid_params }.not_to change(ResponseSource, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
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

  describe 'POST /api/v1/accounts/{account.id}/response_sources/{response_source.id}/add_document' do
    let!(:response_source) { create(:response_source, account: account) }
    let(:valid_params) do
      { document_link: 'http://test.test' }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/response_sources/#{response_source.id}/add_document",
               params: valid_params
        end.not_to change(ResponseDocument, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the response sources and documents' do
        expect do
          post "/api/v1/accounts/#{account.id}/response_sources/#{response_source.id}/add_document", headers: admin.create_new_auth_token,
                                                                                                     params: valid_params
        end.to change(ResponseDocument, :count).by(1)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/response_sources/{response_source.id}/remove_document' do
    let!(:response_source) { create(:response_source, account: account) }
    let!(:response_document) { response_source.response_documents.create!(document_link: 'http://test.test') }
    let(:valid_params) do
      { document_id: response_document.id }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/response_sources/#{response_source.id}/remove_document",
               params: valid_params
        end.not_to change(ResponseDocument, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the response sources and documents' do
        expect do
          post "/api/v1/accounts/#{account.id}/response_sources/#{response_source.id}/remove_document", headers: admin.create_new_auth_token,
                                                                                                        params: valid_params
        end.to change(ResponseDocument, :count).by(-1)
        expect(response).to have_http_status(:success)

        expect { response_document.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
