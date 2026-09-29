require 'rails_helper'

RSpec.describe Passkeys do
  describe '.relying_party' do
    it 'uses the origin of FRONTEND_URL even when it carries a path or trailing slash' do
      with_modified_env(FRONTEND_URL: 'https://chat.example.com:8443/app/') do
        relying_party = described_class.relying_party

        expect(relying_party.id).to eq('chat.example.com')
        expect(relying_party.allowed_origins).to eq(['https://chat.example.com:8443'])
      end
    end
  end

  describe '.enabled?' do
    it 'is off until the installation turns it on' do
      with_modified_env(FRONTEND_URL: 'https://chat.example.com') do
        expect(described_class.enabled?).to be(false)
      end
    end
  end
end
