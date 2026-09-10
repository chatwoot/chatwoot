require 'rails_helper'

RSpec.describe Crm::Cpfcnpj::Document do
  describe '.normalize' do
    it 'strips punctuation and upcases' do
      expect(described_class.normalize('11.222.333/0001-81')).to eq('11222333000181')
    end

    it 'returns an empty string for nil' do
      expect(described_class.normalize(nil)).to eq('')
    end
  end

  describe '.type' do
    it 'detects a valid cpf' do
      expect(described_class.type('111.444.777-35')).to eq(:cpf)
    end

    it 'detects a valid cnpj' do
      expect(described_class.type('11.222.333/0001-81')).to eq(:cnpj)
    end

    it 'returns nil for an invalid cpf check digit' do
      expect(described_class.type('12345678900')).to be_nil
    end

    it 'returns nil for an invalid cnpj check digit' do
      expect(described_class.type('11222333000180')).to be_nil
    end

    it 'rejects repeated digit sequences' do
      expect(described_class.type('00000000000')).to be_nil
    end
  end

  describe '.valid?' do
    it 'is true for a valid document' do
      expect(described_class).to be_valid('11222333000181')
    end

    it 'is false for a malformed document' do
      expect(described_class).not_to be_valid('123')
    end
  end

  describe '.extract_from' do
    let(:account) { create(:account) }

    it 'reads the configured custom attribute' do
      contact = create(:contact, account: account, custom_attributes: { 'cpf_cnpj' => '11.222.333/0001-81' })
      expect(described_class.extract_from(contact, 'cpf_cnpj')).to eq('11222333000181')
    end

    it 'falls back to the identifier when the attribute is blank' do
      contact = create(:contact, account: account, identifier: '11144477735', custom_attributes: {})
      expect(described_class.extract_from(contact, 'cpf_cnpj')).to eq('11144477735')
    end

    it 'returns nil when no valid document is present' do
      contact = create(:contact, account: account, identifier: 'not-a-doc', custom_attributes: {})
      expect(described_class.extract_from(contact, 'cpf_cnpj')).to be_nil
    end
  end
end
