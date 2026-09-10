require 'rails_helper'

RSpec.describe Integrations::Stripe::Oauth do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:authorize_url) { 'https://marketplace.stripe.com/oauth/v2/test/authorize?client_id=ca_test' }

  before do
    allow(GlobalConfig).to receive(:get_value).and_call_original
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_AUTHORIZE_URL').and_return(authorize_url)
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_SECRET_KEY').and_return('sk_test_app')
  end

  it 'requires both installation settings and encryption' do
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
    expect(described_class.configured?).to be true
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_SECRET_KEY').and_return(nil)
    expect(described_class.configured?).to be false
  end

  it 'is unavailable without encryption' do
    allow(Chatwoot).to receive(:encryption_configured?).and_return(false)
    expect(described_class.configured?).to be false
  end

  it 'does not advertise malformed settings as configured' do
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_AUTHORIZE_URL').and_return('not a URL')
    expect(described_class.configured?).to be false
  end

  it 'allows clearing configuration but rejects incomplete and malformed values' do
    expect(described_class.configuration_errors(url: '', key: '')).to be_empty
    expect(described_class.configuration_errors(url: authorize_url, key: '')).not_to be_empty
    expect(described_class.configuration_errors(url: authorize_url, key: 'sk_live_example')).to be_empty
    expect(described_class.configuration_errors(url: 'https://user@marketplace.stripe.com/authorize', key: 'sk_test_example')).not_to be_empty
  end

  it 'uses the Stripe Apps token endpoint with test and live keys' do
    expect(described_class.client.token_url).to eq('https://api.stripe.com/v1/oauth/token')
    expect(described_class.livemode?).to be false
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_SECRET_KEY').and_return('sk_live_app')
    expect(described_class.client.id).to eq('sk_live_app')
    expect(described_class.livemode?).to be true
  end

  it 'rejects non-secret keys' do
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_SECRET_KEY').and_return('pk_live_app')
    expect { described_class.client }.to raise_error(ArgumentError)
  end

  it 'preserves install parameters and creates a one-use state bound to the initiating administrator' do
    with_modified_env FRONTEND_URL: 'https://local.example.com' do
      query = URI.decode_www_form(URI(described_class.authorize_url(account: account, user: user)).query).to_h
      expect(query).to include('client_id' => 'ca_test', 'redirect_uri' => 'https://local.example.com/stripe/callback')
      expect(query['state']).to match(/\A[0-9a-f]{64}\z/)
      expect(described_class.consume_state(query['state'])).to eq('account_id' => account.id, 'user_id' => user.id, 'livemode' => false)
      expect(described_class.consume_state(query['state'])).to be_nil
    end
  end

  it 'binds live authorizations to live-mode state' do
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_SECRET_KEY').and_return('sk_live_app')
    query = URI.decode_www_form(URI(described_class.authorize_url(account: account, user: user)).query).to_h
    expect(described_class.consume_state(query.fetch('state'))).to include('livemode' => true)
  end

  it 'rejects malformed and unknown state' do
    expect(described_class.consume_state(nil)).to be_nil
    expect(described_class.consume_state('invalid')).to be_nil
    expect(described_class.consume_state('a' * 64)).to be_nil
  end

  it 'assigns a ten-minute lifetime to OAuth state' do
    expect(Redis::Alfred).to receive(:setex).with(/\Astripe_app:oauth:[0-9a-f]{64}\z/, anything, 600).and_call_original
    described_class.authorize_url(account: account, user: user)
  end

  it 'rejects authorization links outside the Stripe marketplace' do
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_AUTHORIZE_URL').and_return('https://example.com/authorize')
    expect { described_class.authorize_url(account: account, user: user) }.to raise_error(ArgumentError)
  end
end
