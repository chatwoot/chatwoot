require 'rails_helper'

RSpec.describe 'api/v1/models/_user', type: :view do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }

  before { account.enable_features!(:api_and_webhooks) }

  after { Current.reset }

  it 'returns credentials for the authenticated administrator themselves' do
    Current.user = user

    render partial: 'api/v1/models/user', formats: [:json], locals: { resource: user }

    expect(JSON.parse(rendered)).to include('access_token' => user.access_token.token, 'pubsub_token' => user.pubsub_token)
  end

  it 'omits another user\'s credentials for an account administrator' do
    Current.user = create(:user, account: account, role: :administrator)

    render partial: 'api/v1/models/user', formats: [:json], locals: { resource: user }

    expect(JSON.parse(rendered)).not_to have_key('access_token')
    expect(JSON.parse(rendered)).not_to have_key('pubsub_token')
  end

  it 'omits credentials without an authenticated user' do
    Current.user = nil

    render partial: 'api/v1/models/user', formats: [:json], locals: { resource: user }

    expect(JSON.parse(rendered)).not_to have_key('access_token')
    expect(JSON.parse(rendered)).not_to have_key('pubsub_token')
  end

  it 'returns credentials for the user authenticated by the auth response' do
    Current.user = nil

    render partial: 'api/v1/models/user', formats: [:json], locals: { resource: user, authenticated_user: user }

    expect(JSON.parse(rendered)).to include('access_token' => user.access_token.token, 'pubsub_token' => user.pubsub_token)
  end

  it 'omits credentials when the supplied authenticated user is someone else' do
    authenticated_user = create(:user)

    render partial: 'api/v1/models/user', formats: [:json], locals: { resource: user, authenticated_user: authenticated_user }

    expect(JSON.parse(rendered)).not_to have_key('access_token')
    expect(JSON.parse(rendered)).not_to have_key('pubsub_token')
  end
end
