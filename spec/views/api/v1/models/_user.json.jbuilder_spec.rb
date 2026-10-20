require 'rails_helper'

RSpec.describe 'api/v1/models/_user', type: :view do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { account.enable_features!(:api_and_webhooks) }

  after { Current.reset }

  it 'returns credentials for the authenticated user' do
    Current.user = user

    render partial: 'api/v1/models/user', formats: [:json], locals: { resource: user }

    expect(JSON.parse(rendered)).to include('access_token' => user.access_token.token, 'pubsub_token' => user.pubsub_token)
  end

  it 'omits credentials for a different user' do
    Current.user = create(:user)

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
end
