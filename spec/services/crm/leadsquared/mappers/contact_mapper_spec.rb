require 'rails_helper'

RSpec.describe Crm::Leadsquared::Mappers::ContactMapper do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, name: '', last_name: '', country_code: '') }
  let(:brand_name) { 'Test Brand' }

  before do
    allow(GlobalConfig).to receive(:get).with('BRAND_NAME').and_return({ 'BRAND_NAME' => brand_name })
  end

  describe '.map' do
    context 'when contact has basic attributes' do
      it 'maps basic contact attributes correctly' do
        contact.update!(
          name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          phone_number: '+1234567890'
        )

        mapped_data = described_class.map(contact)

        expect(mapped_data).to include(
          'FirstName' => 'John',
          'LastName' => 'Doe',
          'EmailAddress' => 'john@example.com',
          'Mobile' => '+1234567890',
          'Source' => 'Test Brand'
        )
      end
    end

    context 'when contact has additional attributes' do
      it 'maps additional attributes correctly' do
        contact.update!(
          additional_attributes: {
            'company_name' => 'Acme Corp',
            'address' => '123 Main St',
            'city' => 'San Francisco'
          }
        )

        mapped_data = described_class.map(contact)

        expect(mapped_data).to include(
          'mx_Company' => 'Acme Corp',
          'mx_Address' => '123 Main St',
          'mx_City' => 'San Francisco'
        )
      end
    end

    context 'when contact has country code' do
      it 'maps country code correctly' do
        contact.update!(additional_attributes: { 'country' => 'US' })

        mapped_data = described_class.map(contact)

        expect(mapped_data).to include('mx_Country' => 'US')
      end
    end

    context 'when contact has missing attributes' do
      it 'sets LastName to Unknown when missing' do
        contact.update!(last_name: '')

        mapped_data = described_class.map(contact)

        expect(mapped_data['LastName']).to eq('Unknown')
      end

      it 'excludes optional attributes when missing' do
        contact.update!(
          name: '',
          email: '',
          phone_number: '',
          country_code: '',
          additional_attributes: {}
        )

        mapped_data = described_class.map(contact)

        expect(mapped_data.keys).not_to include(
          'FirstName',
          'EmailAddress',
          'Mobile',
          'mx_Country',
          'mx_Company',
          'mx_Address',
          'mx_City'
        )
      end
    end
  end
end
