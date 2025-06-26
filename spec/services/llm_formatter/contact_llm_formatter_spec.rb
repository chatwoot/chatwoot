require 'rails_helper'

RSpec.describe LlmFormatter::ContactLlmFormatter do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, name: 'John Doe', email: 'john@example.com', phone_number: '+1234567890') }
  let(:formatter) { described_class.new(contact) }

  describe '#format' do
    context 'when contact has no notes' do
      it 'formats contact details correctly' do
        expected_output = [
          "Contact ID: ##{contact.id}",
          'Contact Attributes:',
          'Name: John Doe',
          'Email: john@example.com',
          'Phone: +1234567890',
          'Location: ',
          'Country Code: ',
          'Contact Notes:',
          'No notes for this contact'
        ].join("\n")

        expect(formatter.format).to eq(expected_output)
      end
    end

    context 'when contact has notes' do
      before do
        create(:note, account: account, contact: contact, content: 'First interaction')
        create(:note, account: account, contact: contact, content: 'Follow up needed')
      end

      it 'includes notes in the output' do
        expected_output = [
          "Contact ID: ##{contact.id}",
          'Contact Attributes:',
          'Name: John Doe',
          'Email: john@example.com',
          'Phone: +1234567890',
          'Location: ',
          'Country Code: ',
          'Contact Notes:',
          ' - First interaction',
          ' - Follow up needed'
        ].join("\n")

        expect(formatter.format).to eq(expected_output)
      end
    end

    context 'when contact has custom attributes' do
      let!(:custom_attribute) do
        create(:custom_attribute_definition, account: account, attribute_model: 'contact_attribute', attribute_display_name: 'Company')
      end

      before do
        contact.update(custom_attributes: { custom_attribute.attribute_key => 'Acme Inc' })
      end

      it 'includes custom attributes in the output' do
        expected_output = [
          "Contact ID: ##{contact.id}",
          'Contact Attributes:',
          'Name: John Doe',
          'Email: john@example.com',
          'Phone: +1234567890',
          'Location: ',
          'Country Code: ',
          'Company: Acme Inc',
          'Contact Notes:',
          'No notes for this contact'
        ].join("\n")

        expect(formatter.format).to eq(expected_output)
      end
    end
  end
end
