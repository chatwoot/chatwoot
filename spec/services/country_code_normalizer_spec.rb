require 'rails_helper'

RSpec.describe CountryCodeNormalizer do
  describe '.normalize' do
    it 'supports the historical country code still emitted by the selector' do
      expect(described_class.normalize(' an ')).to eq('AN')
      expect(described_class.normalize('Netherlands Antilles')).to eq('AN')
      expect(described_class.name_for('AN')).to eq('Netherlands Antilles')
    end

    it 'does not treat an unknown country code as a historical country' do
      expect(described_class.normalize('ZZ')).to be_nil
      expect(described_class.name_for('Unknown country')).to be_nil
    end
  end
end
