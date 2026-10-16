require 'rails_helper'

RSpec.describe DeviseOverrides::RegistrationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST #create (user-enumeration guard)' do
    # https://github.com/chatwoot/chatwoot/issues/15657
    # The default /auth registration endpoint reveals whether an email is
    # already on file by including `email: ['has already been taken']` in
    # the response. The only other validation that can come back is
    # `name: ['can't be blank']`, so anyone hitting /auth can enumerate
    # registered accounts with one POST per guess.
    let!(:existing) { create(:user, name: 'Existing User', email: 'existing@example.com') }

    it 'does not leak email uniqueness when name is blank and email is unknown' do
      post :create, params: { email: 'unknown@example.com', name: '', password: 'Test@123456' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include('errors')
      body = response.parsed_body
      expect(body['errors']).to have_key('name')
      expect(body['errors']).not_to have_key('email')
    end

    it 'does not leak email uniqueness when name is blank and email is already taken' do
      post :create, params: { email: existing.email, name: '', password: 'Test@123456' }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body['errors']).to have_key('name')
      expect(body['errors']).not_to have_key('email')
    end

    it 'returns identical error shapes for known and unknown emails when name is blank' do
      post :create, params: { email: 'unknown@example.com', name: '', password: 'Test@123456' }
      unknown_body = response.parsed_body

      post :create, params: { email: existing.email, name: '', password: 'Test@123456' }
      known_body = response.parsed_body

      expect(unknown_body['errors'].keys).to match_array(known_body['errors'].keys)
    end
  end
end
