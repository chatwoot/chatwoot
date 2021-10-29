require 'rails_helper'

RSpec.describe 'Callbacks API', type: :request do
  before do
    stub_request(:any, /graph.facebook.com/)
    # Mock new and return instance doubles defined above
    allow(Koala::Facebook::OAuth).to receive(:new).and_return(koala_oauth)
    allow(Koala::Facebook::API).to receive(:new).and_return(koala_api)

    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
    allow(koala_api).to receive(:get_connections).and_return(
      [{ 'id' => facebook_page.page_id, 'access_token' => SecureRandom.hex(10) }]
    )
    allow(koala_oauth).to receive(:exchange_access_token_info).and_return('access_token' => SecureRandom.hex(10))
  end

  let(:account) { create(:account) }
  let!(:facebook_page) { create(:channel_facebook_page, inbox: inbox, account: account) }
  let(:valid_params) { attributes_for(:channel_facebook_page).merge(inbox_name: 'Test Inbox') }
  let(:inbox) { create(:inbox, account: account) }

  # Doubles
  let(:koala_api) { instance_double(Koala::Facebook::API) }
  let(:koala_oauth) { instance_double(Koala::Facebook::OAuth) }

  describe 'POST /api/v1/accounts/{account.id}/callbacks/register_facebook_page' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/callbacks/register_facebook_page"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'registers a new facebook page with no avatar' do
        post "/api/v1/accounts/#{account.id}/callbacks/register_facebook_page",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'registers a new facebook page with avatar' do
        buf = OpenURI::Buffer.new
        io = buf.io
        io.base_uri = URI.parse('https://example.org')
        allow_any_instance_of(URI::HTTP).to receive(:open).and_return(io) # rubocop:disable RSpec/AnyInstance

        post "/api/v1/accounts/#{account.id}/callbacks/register_facebook_page",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'registers a new facebook page with avatar on redirect' do
        allow_any_instance_of(URI::HTTP).to receive(:open).and_raise(OpenURI::HTTPRedirect.new(nil, nil, URI.parse('https://example.org'))) # rubocop:disable RSpec/AnyInstance

        post "/api/v1/accounts/#{account.id}/callbacks/register_facebook_page",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/callbacks/facebook_pages' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/callbacks/facebook_pages"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns facebook pages of account' do
        post "/api/v1/accounts/#{account.id}/callbacks/facebook_pages",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(facebook_page.page_id.to_s)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/callbacks/reauthorize_page' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/callbacks/reauthorize_page"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'reauthorizes the page' do
        params = { inbox_id: inbox.id }

        post "/api/v1/accounts/#{account.id}/callbacks/reauthorize_page",
             headers: admin.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(inbox.id.to_s)
      end

      it 'returns unprocessable_entity if no page found' do
        allow(koala_api).to receive(:get_connections).and_return([])
        params = { inbox_id: inbox.id }

        post "/api/v1/accounts/#{account.id}/callbacks/reauthorize_page",
             headers: admin.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
