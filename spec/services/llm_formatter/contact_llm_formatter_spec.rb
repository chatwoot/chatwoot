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
      let(:alice) { create(:user, account: account, name: 'Alice') }

      before do
        create(:note, account: account, contact: contact, content: 'First interaction', user: alice)
        create(:note, account: account, contact: contact, content: 'Follow up needed')
      end

      it 'includes notes in the output' do
        formatted_contact = formatter.format

        expect(formatted_contact).to include('First interaction')
        expect(formatted_contact).to include('Author: Alice')
        expect(formatted_contact).to include('Source: manual')
        expect(formatted_contact).to match(/Created: \d{4}-\d{2}-\d{2}T/)
      end

      it 'uses unknown author when note has no creator' do
        create(:note, account: account, contact: contact, content: 'Imported note', user: nil, updated_by: nil)

        expect(formatter.format).to include('Imported note (Author: Unknown; Source: manual; Created:')
      end

      it 'preloads note authors while formatting notes' do
        bob = create(:user, account: account, name: 'Bob')
        create(:note, account: account, contact: contact, content: 'Bob note', user: bob)
        user_queries = []

        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _started, _finished, _id, payload|
          user_queries << payload[:sql] if payload[:sql].include?('FROM "users"') && !payload[:cached]
        end
        begin
          formatter.format
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        expect(user_queries.count).to eq(1)
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
