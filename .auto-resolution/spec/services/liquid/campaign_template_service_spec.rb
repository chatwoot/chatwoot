require 'rails_helper'

describe Liquid::CampaignTemplateService do
  subject(:template_service) { described_class.new(campaign: campaign, contact: contact) }

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, name: 'John Doe', phone_number: '+1234567890') }
  let(:campaign) { create(:campaign, account: account, inbox: inbox, sender: agent, message: message_content) }

  describe '#call' do
    context 'with liquid template variables' do
      let(:message_content) { 'Hello {{contact.name}}, this is {{agent.name}} from {{account.name}}' }

      it 'processes liquid template correctly' do
        result = template_service.call(message_content)
        agent_drop_name = UserDrop.new(agent).name
        contact_drop_name = ContactDrop.new(contact).name

        expect(result).to eq("Hello #{contact_drop_name}, this is #{agent_drop_name} from #{account.name}")
      end
    end

    context 'with code blocks' do
      let(:message_content) { 'Check this code: `const x = {{contact.name}}`' }

      it 'preserves code blocks without processing liquid' do
        result = template_service.call(message_content)

        expect(result).to include('`const x = {{contact.name}}`')
        expect(result).not_to include(contact.name)
      end
    end

    context 'with multiline code blocks' do
      let(:message_content) do
        <<~MESSAGE
          Here's some code:
          ```
          function greet() {
            return "Hello {{contact.name}}";
          }
          ```
        MESSAGE
      end

      it 'preserves multiline code blocks without processing liquid' do
        result = template_service.call(message_content)

        expect(result).to include('{{contact.name}}')
        expect(result).not_to include(contact.name)
      end
    end

    context 'with malformed liquid syntax' do
      let(:message_content) { 'Hello {{contact.name missing closing braces' }

      it 'returns original message when liquid parsing fails' do
        result = template_service.call(message_content)

        expect(result).to eq(message_content)
      end
    end

    context 'with invalid liquid tags' do
      let(:message_content) { 'Hello {% invalid_tag %} world' }

      it 'returns original message when liquid parsing fails' do
        result = template_service.call(message_content)

        expect(result).to eq(message_content)
      end
    end

    context 'with mixed content' do
      let(:message_content) { 'Hi {{contact.name}}, use this code: `{{agent.name}}` to contact {{agent.name}}' }

      it 'processes liquid outside code blocks but preserves code blocks' do
        result = template_service.call(message_content)
        agent_drop_name = UserDrop.new(agent).name
        contact_drop_name = ContactDrop.new(contact).name

        expect(result).to include("Hi #{contact_drop_name}")
        expect(result).to include("contact #{agent_drop_name}")
        expect(result).to include('`{{agent.name}}`')
      end
    end

    context 'with all drop types' do
      let(:message_content) do
        'Contact: {{contact.name}}, Agent: {{agent.name}}, Inbox: {{inbox.name}}, Account: {{account.name}}'
      end

      it 'processes all available drops' do
        result = template_service.call(message_content)
        agent_drop_name = UserDrop.new(agent).name
        contact_drop_name = ContactDrop.new(contact).name

        expect(result).to include("Contact: #{contact_drop_name}")
        expect(result).to include("Agent: #{agent_drop_name}")
        expect(result).to include("Inbox: #{inbox.name}")
        expect(result).to include("Account: #{account.name}")
      end
    end
  end
end
