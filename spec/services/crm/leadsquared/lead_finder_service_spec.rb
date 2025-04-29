require 'rails_helper'

RSpec.describe Crm::Leadsquared::LeadFinderService do
  let(:lead_client) { instance_double(Crm::Leadsquared::Api::LeadClient) }
  let(:service) { described_class.new(lead_client) }
  let(:contact) { create(:contact, email: 'test@example.com', phone_number: '+1234567890') }

  describe '#find_or_create' do
    context 'when contact has stored lead ID' do
      before do
        contact.additional_attributes = { 'external' => { 'leadsquared_id' => '123' } }
        contact.save!
      end

      it 'returns the stored lead ID' do
        result = service.find_or_create(contact)
        expect(result).to eq('123')
      end
    end

    context 'when contact has no stored lead ID' do
      context 'when lead is found by email' do
        before do
          allow(lead_client).to receive(:search_lead)
            .with(contact.email)
            .and_return([{ 'ProspectID' => '456' }])
        end

        it 'returns the found lead ID' do
          result = service.find_or_create(contact)
          expect(result).to eq('456')
        end
      end

      context 'when lead is found by phone' do
        before do
          allow(lead_client).to receive(:search_lead)
            .with(contact.email)
            .and_return([])

          allow(lead_client).to receive(:search_lead)
            .with(contact.phone_number)
            .and_return([{ 'ProspectID' => '789' }])
        end

        it 'returns the found lead ID' do
          result = service.find_or_create(contact)
          expect(result).to eq('789')
        end
      end

      context 'when lead is not found and needs to be created' do
        before do
          allow(lead_client).to receive(:search_lead)
            .with(contact.email)
            .and_return([])

          allow(lead_client).to receive(:search_lead)
            .with(contact.phone_number)
            .and_return([])

          allow(lead_client).to receive(:create_or_update_lead)
            .with(Crm::Leadsquared::Mappers::ContactMapper.map(contact))
            .and_return('999')
        end

        it 'creates a new lead and returns its ID' do
          result = service.find_or_create(contact)
          expect(result).to eq('999')
        end
      end

      context 'when lead creation fails' do
        before do
          allow(lead_client).to receive(:search_lead)
            .with(contact.email)
            .and_return([])

          allow(lead_client).to receive(:search_lead)
            .with(contact.phone_number)
            .and_return([])

          allow(Crm::Leadsquared::Mappers::ContactMapper).to receive(:map)
            .with(contact)
            .and_return({})

          allow(lead_client).to receive(:create_or_update_lead)
            .with({})
            .and_raise(StandardError, 'Failed to create lead')
        end

        it 'raises an error' do
          expect { service.find_or_create(contact) }.to raise_error(StandardError, 'Failed to create lead')
        end
      end
    end
  end
end
