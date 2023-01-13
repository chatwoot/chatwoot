require 'rails_helper'

RSpec.describe 'Microsoft::CallbacksController', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:microsoft_client) do
    OAuth2::Client.new('client_id', 'client_secret', {
                         site: 'https://login.microsoftonline.com',
                         redirect_uri: 'http://0.0.0.0/microsoft/callback',
                         authorize_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
                       })
  end
  let(:auth_code) { microsoft_client.auth_code }

  before do
    ::Redis::Alfred.set('test@test.com', account.id)
    OAuth2::Response.register_parser(:id_token, ['application/json']) do |_body|
      { id_token: JWT.encode({ email: 'test@test.com', name: 'test' }, false) }
    end
  end

  describe 'GET /microsoft/callback' do
    it 'creates inboxes if authentication is successful' do
      headers = { 'Content-Type' => 'application/json' }
      body = { id_token: JWT.encode({ email: 'test@test.com', name: 'test' }, false) }
      microsoft_response = instance_double('response', headers: headers, body: body)
      subject = OAuth2::Response.new(microsoft_response)
      # subject.parsed
      response = instance_double(::OAuth2::Response, response: subject)
      allow(::OAuth2::Client).to receive(:new).and_return(microsoft_client)
      allow(microsoft_client).to receive(:auth_code).and_return(auth_code)
      allow(auth_code).to receive(:get_token).and_return(response)

      get microsoft_callback_url

      account.reload
      expect(response).to redirect_to app_microsoft_inbox_agents_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      expect(account.inboxes.last.name).to eq 'test'
    end
  end
end
