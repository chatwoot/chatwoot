require 'rails_helper'

RSpec.describe Crm::Cpfcnpj::ProcessorService do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :cpfcnpj, account: account) }
  let(:service) { described_class.new(hook) }
  let(:client) { instance_double(Crm::Cpfcnpj::Api::BaseClient) }

  before do
    account.enable_features('cpfcnpj_integration')
    allow(Crm::Cpfcnpj::Api::BaseClient).to receive(:new).and_return(client)
    allow(client).to receive(:lookup)
  end

  def load_fixture(name)
    JSON.parse(Rails.root.join('spec/fixtures/cpfcnpj', name).read)
  end

  describe '.crm_name' do
    it 'returns cpfcnpj' do
      expect(described_class.crm_name).to eq('cpfcnpj')
    end
  end

  describe '#handle_contact' do
    context 'when the contact has no document' do
      let(:contact) { create(:contact, account: account, identifier: nil, custom_attributes: {}) }

      it 'does not call the API' do
        service.handle_contact(contact)
        expect(client).not_to have_received(:lookup)
      end
    end

    context 'when the document is invalid' do
      let(:contact) { create(:contact, account: account, custom_attributes: { 'cpf_cnpj' => '12345678900' }) }

      it 'does not call the API' do
        service.handle_contact(contact)
        expect(client).not_to have_received(:lookup)
      end
    end

    context 'when the contact already carries the same document' do
      let(:contact) do
        create(:contact, account: account,
                         custom_attributes: { 'cpf_cnpj' => '11222333000181' },
                         additional_attributes: { 'cpfcnpj' => { 'document' => '11222333000181' } })
      end

      it 'skips the lookup to avoid an update loop' do
        service.handle_contact(contact)
        expect(client).not_to have_received(:lookup)
      end
    end

    context 'when a new cnpj contact is enriched' do
      let(:contact) { create(:contact, account: account, name: '', custom_attributes: { 'cpf_cnpj' => '11222333000181' }) }

      before do
        allow(client).to receive(:lookup).with('11222333000181', 6).and_return(load_fixture('cnpj_package_6.json'))
      end

      it 'stores the enrichment and company fields' do
        service.handle_contact(contact)
        contact.reload
        expect(contact.additional_attributes['cpfcnpj']['name']).to eq('TOKEN TEST LTDA')
        expect(contact.additional_attributes['company_name']).to eq('TOKEN TEST LTDA')
        expect(contact.name).to eq('TOKEN TEST LTDA')
      end
    end

    context 'when the contact is a cpf and cpf enrichment is disabled' do
      let(:hook) { create(:integrations_hook, :cpfcnpj, account: account, settings: settings) }
      let(:settings) { { 'token' => 'a' * 32, 'cnpj_package' => 6, 'cpf_package' => 1, 'enrich_cpf' => false } }
      let(:contact) { create(:contact, account: account, custom_attributes: { 'cpf_cnpj' => '11144477735' }) }

      it 'does not call the API' do
        service.handle_contact(contact)
        expect(client).not_to have_received(:lookup)
      end
    end

    context 'when the API rejects the document itself' do
      let(:contact) { create(:contact, account: account, custom_attributes: { 'cpf_cnpj' => '11222333000181' }) }
      let(:api_error) { Crm::Cpfcnpj::Api::BaseClient::ApiError.new('boom', code: 202, response: nil) }

      before do
        allow(client).to receive(:lookup).and_raise(api_error)
        allow(Rails.logger).to receive(:warn)
        allow(ChatwootExceptionTracker).to receive(:new).and_call_original
      end

      it 'captures the error and stores the outcome so the document is not looked up again' do
        expect { service.handle_contact(contact) }.not_to raise_error
        expect(ChatwootExceptionTracker).not_to have_received(:new)
        expect(contact.reload.additional_attributes.dig('cpfcnpj', 'error_code')).to eq(202)
        expect(contact.additional_attributes.dig('cpfcnpj', 'name')).to be_nil

        service.handle_contact(contact)
        expect(client).to have_received(:lookup).once
      end
    end

    context 'when the API fails for an account level reason' do
      let(:contact) { create(:contact, account: account, custom_attributes: { 'cpf_cnpj' => '11222333000181' }) }
      let(:api_error) { Crm::Cpfcnpj::Api::BaseClient::ApiError.new('no credits', code: 1001, response: nil) }

      before do
        allow(client).to receive(:lookup).and_raise(api_error)
        allow(Rails.logger).to receive(:warn)
        allow(ChatwootExceptionTracker).to receive(:new).and_call_original
      end

      it 'leaves the contact untouched so the lookup is retried on the next event' do
        expect { service.handle_contact(contact) }.not_to raise_error
        expect(contact.reload.additional_attributes['cpfcnpj']).to be_nil

        service.handle_contact(contact)
        expect(client).to have_received(:lookup).twice
      end
    end

    context 'when the lookup times out' do
      let(:contact) { create(:contact, account: account, custom_attributes: { 'cpf_cnpj' => '11222333000181' }) }

      before do
        allow(client).to receive(:lookup).and_raise(Net::OpenTimeout)
        allow(Rails.logger).to receive(:warn)
        allow(ChatwootExceptionTracker).to receive(:new).and_call_original
      end

      it 'does not propagate the timeout' do
        expect { service.handle_contact(contact) }.not_to raise_error
        expect(ChatwootExceptionTracker).not_to have_received(:new)
      end
    end

    context 'when an unexpected error happens' do
      let(:contact) { create(:contact, account: account, custom_attributes: { 'cpf_cnpj' => '11222333000181' }) }
      let(:tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }

      before do
        allow(client).to receive(:lookup).and_raise(RuntimeError, 'boom')
        allow(Rails.logger).to receive(:error)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)
      end

      it 'reports it to the exception tracker and does not raise' do
        expect { service.handle_contact(contact) }.not_to raise_error
        expect(tracker).to have_received(:capture_exception)
      end
    end

    context 'when write_custom_attributes is enabled' do
      let(:hook) { create(:integrations_hook, :cpfcnpj, account: account, settings: settings) }
      let(:settings) { { 'token' => 'a' * 32, 'cnpj_package' => 6, 'cpf_package' => 1, 'write_custom_attributes' => true } }
      let(:contact) { create(:contact, account: account, custom_attributes: { 'cpf_cnpj' => '11222333000181' }) }

      before do
        allow(client).to receive(:lookup).and_return(load_fixture('cnpj_package_6.json'))
      end

      it 'creates the attribute definitions idempotently and writes values' do
        expect { service.handle_contact(contact) }
          .to change(account.custom_attribute_definitions, :count).by(5)

        service.handle_contact(contact)
        expect(account.custom_attribute_definitions.count).to eq(5)
        expect(contact.reload.custom_attributes['cpfcnpj_name']).to eq('TOKEN TEST LTDA')
      end

      it 'writes the lookup date in the format expected by date attributes' do
        service.handle_contact(contact)
        expect(contact.reload.custom_attributes['cpfcnpj_looked_up_at']).to match(/\A\d{4}-\d{2}-\d{2}\z/)
      end

      it 'recovers when another job created a definition first' do
        relation = hook.account.custom_attribute_definitions
        allow(hook.account).to receive(:custom_attribute_definitions).and_return(relation)
        calls = 0
        allow(relation).to receive(:find_or_create_by!).and_wrap_original do |original, *args, &block|
          calls += 1
          raise ActiveRecord::RecordNotUnique, 'duplicate key' if calls == 1

          original.call(*args, &block)
        end

        expect { service.handle_contact(contact) }.not_to raise_error
        expect(contact.reload.custom_attributes['cpfcnpj_name']).to eq('TOKEN TEST LTDA')
      end
    end
  end
end
