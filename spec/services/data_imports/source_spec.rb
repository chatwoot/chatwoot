require 'rails_helper'

RSpec.describe DataImports::Source do
  describe '.source_class' do
    it 'resolves each supported integration adapter', :aggregate_failures do
      expect(described_class.source_class('intercom')).to eq(DataImports::Intercom::Source)
      expect(described_class.source_class('freshdesk')).to eq(DataImports::Freshdesk::Source)
      expect(described_class.supported?('intercom')).to be(true)
      expect(described_class.supported?('freshdesk')).to be(true)
    end

    it 'rejects unsupported providers' do
      expect { described_class.source_class('zendesk') }.to raise_error(ArgumentError, 'Unsupported import source.')
    end
  end

  describe '.for' do
    it 'builds the configured adapter from persisted credentials' do
      data_import = build(:data_import, :freshdesk)

      source = described_class.for(data_import)

      expect(source).to have_attributes(provider: 'freshdesk', display_name: 'Freshdesk')
    end
  end
end
