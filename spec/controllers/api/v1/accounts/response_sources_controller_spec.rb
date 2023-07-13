require 'rails_helper'

RSpec.describe 'Response Sources API', type: :request do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }

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

      it 'creates the contact' do
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
