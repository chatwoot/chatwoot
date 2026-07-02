require 'rails_helper'

RSpec.describe EmailOauth::MicrosoftTenant do
  describe '.resolve' do
    it 'returns the tenant GUID from the credentials' do
      guid = 'a1b2c3d4-1111-2222-3333-444455556666'

      expect(described_class.resolve(tenant_id: guid)).to eq(guid)
    end

    it 'accepts a verified domain as tenant' do
      expect(described_class.resolve(tenant_id: 'contoso.com.br')).to eq('contoso.com.br')
    end

    it 'accepts identity platform literals' do
      expect(described_class.resolve(tenant_id: 'organizations')).to eq('organizations')
    end

    it 'falls back to common when tenant is absent' do
      expect(described_class.resolve(tenant_id: nil)).to eq('common')
      expect(described_class.resolve({})).to eq('common')
    end

    it 'falls back to common on values outside the whitelist (URL injection)' do
      expect(described_class.resolve(tenant_id: 'evil/../../path?x=1')).to eq('common')
      expect(described_class.resolve(tenant_id: 'a b c')).to eq('common')
    end
  end

  describe '.authorize_url / .token_url' do
    it 'builds tenant-specific endpoints' do
      creds = { tenant_id: 'a1b2c3d4-1111-2222-3333-444455556666' }

      expect(described_class.authorize_url(creds))
        .to eq('https://login.microsoftonline.com/a1b2c3d4-1111-2222-3333-444455556666/oauth2/v2.0/authorize')
      expect(described_class.token_url(creds))
        .to eq('https://login.microsoftonline.com/a1b2c3d4-1111-2222-3333-444455556666/oauth2/v2.0/token')
    end

    it 'keeps the upstream /common endpoints without a tenant' do
      expect(described_class.authorize_url({})).to eq('https://login.microsoftonline.com/common/oauth2/v2.0/authorize')
      expect(described_class.token_url({})).to eq('https://login.microsoftonline.com/common/oauth2/v2.0/token')
    end
  end
end
