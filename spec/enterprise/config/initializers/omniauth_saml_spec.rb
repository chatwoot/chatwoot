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

  it 'signs authentication requests with the SLO key when single logout is configured' do
    settings = create(:account_saml_settings, account: account, sls_url: 'https://idp.example.com/saml/slo')

    SAML_SETUP_PROC.call(env)

    expect(strategy.options).to include(certificate: settings.sp_certificate, private_key: settings.sp_private_key)
    expect(strategy.options[:security]).to include(
      authn_requests_signed: true,
      signature_method: XMLSecurity::Document::RSA_SHA256,
      digest_method: XMLSecurity::Document::SHA256
    )
  end

  it 'does not sign authentication requests when single logout is not configured' do
    create(:account_saml_settings, account: account, sls_url: nil)
    strategy.options.merge!(
      certificate: 'another tenant certificate',
      private_key: 'another tenant key',
      security: { authn_requests_signed: true }
    )

    SAML_SETUP_PROC.call(env)

    expect(strategy.options).to include(certificate: nil, private_key: nil)
    expect(strategy.options[:security]).to include(
      authn_requests_signed: false,
      signature_method: XMLSecurity::Document::RSA_SHA256,
      digest_method: XMLSecurity::Document::SHA256
    )
  end

  it 'keeps authentication requests signed when SLO is disabled after its certificate was trusted' do
    settings = create(:account_saml_settings, account: account, sls_url: 'https://idp.example.com/saml/slo')
    settings.update!(sls_url: nil)

    SAML_SETUP_PROC.call(env)

    expect(strategy.options).to include(certificate: settings.sp_certificate, private_key: settings.sp_private_key)
    expect(strategy.options[:security]).to include(authn_requests_signed: true)
  end
end
# rubocop:enable RSpec/DescribeClass
