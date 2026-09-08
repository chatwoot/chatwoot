require 'rails_helper'

describe Enterprise::Billing::Currencies do
  describe 'Brazilian Real (brl)' do
    it 'is a supported currency' do
      expect(described_class.supported?('brl')).to be(true)
    end

    it 'recognizes brl regardless of casing or surrounding whitespace' do
      expect(described_class.supported?('  BRL ')).to be(true)
      expect(described_class.normalize('  BRL ')).to eq('brl')
    end

    it 'keeps brl when coercing to a supported code' do
      expect(described_class.to_supported('BRL')).to eq('brl')
    end

    it 'defaults the pt_BR account locale to brl' do
      expect(described_class.for_locale('pt_BR')).to eq('brl')
    end

    it 'maps brl to Brazil and the pt-BR checkout locale' do
      expect(described_class.country_for('brl')).to eq('BR')
      expect(described_class.preferred_locale_for('brl')).to eq('pt-BR')
    end

    it 'falls back to the usd default for unsupported input' do
      expect(described_class.to_supported('eur')).to eq('usd')
    end

    it 'does not set a country override for usd customers' do
      expect(described_class.country_for('usd')).to be_nil
      expect(described_class.preferred_locale_for('usd')).to be_nil
    end
  end
end
