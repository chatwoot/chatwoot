require 'rails_helper'

RSpec.describe Crm::Leadsquared::Mappers::ContactMapper do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, name: '', last_name: '', country_code: '') }
  let(:brand_name) { 'Test Brand' }

  before do
    allow(GlobalConfig).to receive(:get).with('BRAND_NAME').and_return({ 'BRAND_NAME' => brand_name })
  end

  describe '.map' do
    context 'with basic attributes' do
      it 'maps basic contact attributes correctly' do
        contact.update!(
          name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          # the phone number is intentionally wrong
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

      it 'represents the phone number correctly' do
        contact.update!(
          name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          phone_number: '+917507684392'
        )

        mapped_data = described_class.map(contact)

        expect(mapped_data).to include('Mobile' => '+91-7507684392')
      end
    end
  end
end
