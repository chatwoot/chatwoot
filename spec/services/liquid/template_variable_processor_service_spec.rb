require 'rails_helper'

describe Liquid::TemplateVariableProcessorService do
  subject(:processor) { described_class.new(drops: drops) }

  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, name: 'John Doe', email: 'john@example.com', phone_number: '+1234567890') }
  let(:agent) { create(:user, account: account, name: 'Agent Smith') }
  let(:inbox) { create(:inbox, account: account, name: 'Support Inbox') }

  let(:drops) do
    {
      'contact' => ContactDrop.new(contact),
      'agent' => UserDrop.new(agent),
      'inbox' => InboxDrop.new(inbox),
      'account' => AccountDrop.new(account)
    }
  end

  describe '#process_string' do
    it 'processes simple liquid variable' do
      result = processor.process_string('Hello {{contact.name}}')
      contact_drop_name = ContactDrop.new(contact).name

      expect(result).to eq("Hello #{contact_drop_name}")
    end

    it 'processes multiple liquid variables' do
      result = processor.process_string('{{contact.name}} from {{account.name}}')
      contact_drop_name = ContactDrop.new(contact).name

      expect(result).to eq("#{contact_drop_name} from #{account.name}")
    end

    it 'returns original string when liquid parsing fails' do
      result = processor.process_string('Hello {{contact.invalid_field}}')

      expect(result).to eq('Hello ')
    end

    it 'handles blank strings' do
      result = processor.process_string('')

      expect(result).to eq('')
    end

    it 'handles nil values' do
      result = processor.process_string(nil)

      expect(result).to be_nil
    end
  end

  describe '#process_hash' do
    it 'processes string values in hash' do
      input = { 'greeting' => 'Hello {{contact.name}}' }
      result = processor.process_hash(input)
      contact_drop_name = ContactDrop.new(contact).name

      expect(result['greeting']).to eq("Hello #{contact_drop_name}")
    end

    it 'processes nested hashes' do
      input = {
        'body' => {
          '1' => '{{contact.first_name}}',
          '2' => 'Order {{contact.id}}'
        }
      }
      result = processor.process_hash(input)
      contact_drop = ContactDrop.new(contact)

      expect(result['body']['1']).to eq(contact_drop.first_name)
      expect(result['body']['2']).to eq("Order #{contact.id}")
    end

    it 'preserves non-string values' do
      input = {
        'text' => '{{contact.name}}',
        'number' => 123,
        'boolean' => true,
        'nil_value' => nil
      }
      result = processor.process_hash(input)

      expect(result['number']).to eq(123)
      expect(result['boolean']).to be true
      expect(result['nil_value']).to be_nil
    end

    it 'processes all drop types' do
      input = {
        'contact_name' => '{{contact.name}}',
        'agent_name' => '{{agent.name}}',
        'inbox_name' => '{{inbox.name}}',
        'account_name' => '{{account.name}}'
      }
      result = processor.process_hash(input)
      contact_drop_name = ContactDrop.new(contact).name
      agent_drop_name = UserDrop.new(agent).name

      expect(result['contact_name']).to eq(contact_drop_name)
      expect(result['agent_name']).to eq(agent_drop_name)
      expect(result['inbox_name']).to eq(inbox.name)
      expect(result['account_name']).to eq(account.name)
    end
  end

  describe '#process_value' do
    context 'with arrays' do
      it 'processes array of strings' do
        input = ['Hello {{contact.name}}', '{{agent.name}} here']
        result = processor.process_value(input)
        contact_drop_name = ContactDrop.new(contact).name
        agent_drop_name = UserDrop.new(agent).name

        expect(result).to eq(["Hello #{contact_drop_name}", "#{agent_drop_name} here"])
      end

      it 'processes nested arrays and hashes' do
        input = [
          { 'text' => '{{contact.name}}' },
          { 'text' => '{{agent.name}}' }
        ]
        result = processor.process_value(input)
        contact_drop_name = ContactDrop.new(contact).name
        agent_drop_name = UserDrop.new(agent).name

        expect(result[0]['text']).to eq(contact_drop_name)
        expect(result[1]['text']).to eq(agent_drop_name)
      end
    end

    context 'with complex nested structures' do
      it 'processes deeply nested hash with liquid variables' do
        input = {
          'level1' => {
            'level2' => {
              'message' => 'Hi {{contact.name}}',
              'items' => [
                { 'text' => '{{agent.name}}' },
                { 'value' => 123 }
              ]
            }
          }
        }
        result = processor.process_value(input)
        contact_drop_name = ContactDrop.new(contact).name
        agent_drop_name = UserDrop.new(agent).name

        expect(result['level1']['level2']['message']).to eq("Hi #{contact_drop_name}")
        expect(result['level1']['level2']['items'][0]['text']).to eq(agent_drop_name)
        expect(result['level1']['level2']['items'][1]['value']).to eq(123)
      end
    end
  end

  describe 'error handling' do
    it 'handles malformed liquid syntax gracefully' do
      result = processor.process_string('Hello {{contact.name missing closing')

      expect(result).to eq('Hello {{contact.name missing closing')
    end

    it 'logs warning when liquid parsing fails' do
      expect(Rails.logger).to receive(:warn).with(/Liquid template processing error/)

      processor.process_string('{% invalid_syntax %}')
    end
  end
end

