require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'SAML OmniAuth setup' do
  let(:strategy) { OmniAuth::Strategies::SAML.new(->(_env) { [404, {}, []] }, setup: SAML_SETUP_PROC) }
  let(:rotating_account) { create(:account) }
  let(:single_certificate_account) { create(:account) }

  def run_callback(account)
    env = Rack::MockRequest.env_for("/omniauth/saml/callback?account_id=#{account.id}", method: 'POST')
    env['rack.session'] = {}
    strategy.call(env)
    env['omniauth.strategy']
  end

  before do
    allow(OmniAuth.config).to receive_messages(test_mode: false, on_failure: ->(_env) { [401, {}, []] })
    certificates = Array.new(2) { build(:account_saml_settings).certificate }
    create(:account_saml_settings, account: rotating_account, certificate: certificates.join)
    create(:account_saml_settings, account: single_certificate_account)
  end

  it 'runs each request on its own copy of the strategy options' do
    request_strategy = run_callback(rotating_account)

    expect(request_strategy).not_to equal(strategy)
    expect(request_strategy.options).not_to equal(strategy.options)
    expect(strategy.options[:idp_cert_multi]).to be_nil
  end

  it 'does not carry one account certificates into the next request' do
    rotating_request = run_callback(rotating_account)
    single_certificate_request = run_callback(single_certificate_account)

    expect(rotating_request.options[:idp_cert_multi][:signing].size).to eq(2)
    expect(single_certificate_request.options[:idp_cert_multi]).to be_nil
  end
end
# rubocop:enable RSpec/DescribeClass
