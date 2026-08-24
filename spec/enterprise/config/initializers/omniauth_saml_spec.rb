require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'SAML setup' do
  let(:account) { create(:account) }
  let(:strategy) { Struct.new(:options).new({}) }
  let(:env) do
    Rack::MockRequest.env_for("/omniauth/saml?account_id=#{account.id}").merge(
      'omniauth.strategy' => strategy
    )
  end

  it 'does not start signing authentication requests when single logout is configured' do
    create(:account_saml_settings, account: account, sls_url: 'https://idp.example.com/saml/slo')

    SAML_SETUP_PROC.call(env)

    expect(strategy.options).not_to include(:certificate, :private_key, :security)
  end
end
# rubocop:enable RSpec/DescribeClass
