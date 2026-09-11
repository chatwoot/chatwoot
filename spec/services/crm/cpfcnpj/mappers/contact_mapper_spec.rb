require 'rails_helper'

RSpec.describe Crm::Cpfcnpj::Mappers::ContactMapper do
  let(:account) { create(:account) }

  def load_fixture(name)
    JSON.parse(Rails.root.join('spec/fixtures/cpfcnpj', name).read)
  end

  describe '.map' do
    context 'with a cnpj payload' do
      let(:mapped) { described_class.map('11222333000181', :cnpj, load_fixture('cnpj_package_6.json')) }

      it 'maps the core company fields' do
        expect(mapped).to include(
          'document' => '11222333000181',
          'type' => 'cnpj',
          'name' => 'TOKEN TEST LTDA',
          'trade_name' => 'TOKEN TEST',
          'status' => 'Inapta',
          'city' => 'Montes Claros',
          'state' => 'MG',
          'cnae_code' => '6202300'
        )
      end

      it 'summarises partners without leaking their documents' do
        expect(mapped['partners_count']).to eq(mapped['partners'].size)
        expect(mapped['partners'].first).to eq('name' => 'Joao Jose', 'role' => 'Socio-Administrador')
        expect(mapped['partners'].last).to eq('name' => 'Maria Souza', 'role' => 'Socia')
        expect(mapped['partners'].first.keys).not_to include('document')
      end

      it 'derives the simples and mei flags' do
        expect(mapped['simples_nacional']).to be(false)
        expect(mapped['mei']).to be(false)
      end
    end

    context 'with a lighter cnpj payload' do
      it 'maps package 5 without the registration section' do
        mapped = described_class.map('11222333000181', :cnpj, load_fixture('cnpj_package_5.json'))

        expect(mapped['name']).to eq('TOKEN TEST LTDA')
        expect(mapped['city']).to eq('Montes Claros')
        expect(mapped['status']).to be_nil
        expect(mapped['partners_count']).to eq(0)
      end

      it 'maps package 4 with only the legal name' do
        mapped = described_class.map('11222333000181', :cnpj, load_fixture('cnpj_package_4.json'))

        expect(mapped['name']).to eq('TOKEN TEST LTDA')
        expect(mapped['state']).to be_nil
        expect(mapped['simples_nacional']).to be_nil
        expect(mapped['mei']).to be_nil
      end

      it 'tolerates a scalar where the full profile has a hash' do
        payload = load_fixture('cnpj_package_6.json').merge('situacao' => 'ATIVA')

        expect { described_class.map('11222333000181', :cnpj, payload) }.not_to raise_error
      end

      it 'emits explicit booleans only when the provider answered' do
        payload = load_fixture('cnpj_package_6.json').merge('simplesNacional' => { 'optante' => 'Não', 'mei' => 'Não' })
        mapped = described_class.map('11222333000181', :cnpj, payload)

        expect(mapped['simples_nacional']).to be(false)
        expect(mapped['mei']).to be(false)
      end
    end

    context 'with a cpf payload' do
      let(:mapped) { described_class.map('11144477735', :cpf, load_fixture('cpf_package_26.json')) }

      it 'maps only the LGPD-safe fields' do
        expect(mapped.keys).to contain_exactly('document', 'type', 'name', 'status', 'looked_up_at', 'package')
        expect(mapped).to include('type' => 'cpf', 'name' => 'Test Token', 'status' => 'Regular')
      end
    end
  end

  describe '.apply' do
    let(:contact) { create(:contact, account: account, name: '') }
    let(:mapped) { described_class.map('11222333000181', :cnpj, load_fixture('cnpj_package_6.json')) }

    it 'stores the enrichment payload and fills blank fields' do
      described_class.apply(contact, mapped)
      expect(contact.additional_attributes['cpfcnpj']['name']).to eq('TOKEN TEST LTDA')
      expect(contact.name).to eq('TOKEN TEST LTDA')
      expect(contact.additional_attributes['company_name']).to eq('TOKEN TEST LTDA')
      expect(contact.additional_attributes['city']).to eq('Montes Claros')
      expect(contact.additional_attributes['country_code']).to eq('BR')
    end

    it 'does not overwrite an existing name' do
      contact.update!(name: 'Existing Name')
      described_class.apply(contact, mapped)
      expect(contact.name).to eq('Existing Name')
    end

    it 'refreshes the fields written by a previous enrichment when the document changes' do
      described_class.apply(contact, mapped)
      other = mapped.merge('document' => '27272134000118', 'name' => 'OTHER COMPANY LTDA', 'city' => 'Belo Horizonte')

      described_class.apply(contact, other)

      expect(contact.additional_attributes['company_name']).to eq('OTHER COMPANY LTDA')
      expect(contact.additional_attributes['city']).to eq('Belo Horizonte')
      expect(contact.name).to eq('OTHER COMPANY LTDA')
    end

    it 'keeps values the agent edited after the previous enrichment' do
      described_class.apply(contact, mapped)
      contact.additional_attributes['company_name'] = 'Edited by the agent'
      contact.additional_attributes['city'] = 'Edited city'
      other = mapped.merge('document' => '27272134000118', 'name' => 'OTHER COMPANY LTDA', 'city' => 'Belo Horizonte')

      described_class.apply(contact, other)

      expect(contact.additional_attributes['company_name']).to eq('Edited by the agent')
      expect(contact.additional_attributes['city']).to eq('Edited city')
    end

    it 'clears company fields written by a previous enrichment when the new document is a cpf' do
      described_class.apply(contact, mapped)
      person = described_class.map('11144477735', :cpf, load_fixture('cpf_package_1.json'))

      described_class.apply(contact, person)

      expect(contact.additional_attributes).not_to have_key('company_name')
      expect(contact.additional_attributes).not_to have_key('city')
      expect(contact.name).to eq(person['name'])
    end

    it 'clears the city written by a previous enrichment when the new package omits it' do
      described_class.apply(contact, mapped)
      lighter = described_class.map('27272134000118', :cnpj, load_fixture('cnpj_package_4.json'))

      described_class.apply(contact, lighter)

      expect(contact.additional_attributes['company_name']).to eq('TOKEN TEST LTDA')
      expect(contact.additional_attributes).not_to have_key('city')
    end

    it 'keeps agent edited company fields when the new document is a cpf' do
      described_class.apply(contact, mapped)
      contact.additional_attributes['company_name'] = 'Edited by the agent'
      person = described_class.map('11144477735', :cpf, load_fixture('cpf_package_1.json'))

      described_class.apply(contact, person)

      expect(contact.additional_attributes['company_name']).to eq('Edited by the agent')
    end
  end
end
