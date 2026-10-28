require 'rails_helper'

RSpec.describe DataImports::Intercom::SourceBucket do
  describe '.for' do
    it 'maps Intercom source types to Chatwoot inbox buckets' do
      expect(described_class.for('email')).to eq({ key: 'email', name: 'Email' })
      expect(described_class.for('phone_switch')).to eq({ key: 'phone', name: 'Phone' })
      expect(described_class.for('inapp')).to eq({ key: 'messenger', name: 'Messenger' })
      expect(described_class.for('messenger')).to eq({ key: 'messenger', name: 'Messenger' })
      expect(described_class.for('push')).to eq({ key: 'messenger', name: 'Messenger' })
    end

    it 'uses an unknown bucket for unsupported source types' do
      expect(described_class.for('unsupported_source')).to eq({ key: 'unknown', name: 'Unknown' })
    end
  end
end
