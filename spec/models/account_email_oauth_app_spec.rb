require 'rails_helper'

RSpec.describe AccountEmailOauthApp do
  let(:account) { create(:account) }

  def build_app(tenant_id: nil)
    described_class.new(
      account: account, provider: 'microsoft',
      client_id: SecureRandom.uuid, client_secret: SecureRandom.hex(20),
      tenant_id: tenant_id
    )
  end

  describe 'tenant_id' do
    it 'persists into the settings jsonb via store_accessor' do
      app = build_app(tenant_id: 'a1b2c3d4-1111-2222-3333-444455556666')
      app.save!

      expect(app.reload.settings['tenant_id']).to eq('a1b2c3d4-1111-2222-3333-444455556666')
    end

    it 'accepts GUID, verified domain and identity platform literals' do
      %w[a1b2c3d4-1111-2222-3333-444455556666 contoso.com.br common organizations consumers].each do |tenant|
        expect(build_app(tenant_id: tenant)).to be_valid
      end
    end

    it 'is optional (multi-tenant apps keep using /common)' do
      expect(build_app(tenant_id: nil)).to be_valid
      expect(build_app(tenant_id: '')).to be_valid
    end

    it 'rejects values that could break the endpoint URL' do
      ['evil/../../path', 'a b c', 'tenant?x=1', 'x'].each do |tenant|
        expect(build_app(tenant_id: tenant)).not_to be_valid
      end
    end
  end
end
