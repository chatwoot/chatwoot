require 'rails_helper'

describe Whatsapp::LiquidTemplateProcessorService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, name: 'Agent Smith') }
  let(:inbox) { create(:inbox, account: account, name: 'Support Inbox') }
  let(:contact) { create(:contact, account: account, name: 'John Doe', email: 'john@example.com', phone_number: '+1234567890') }
  let(:campaign) { create(:campaign, account: account, inbox: inbox, sender: agent, message: 'Test message') }
  let(:service) { described_class.new(campaign: campaign, contact: contact) }

  describe '#process_template_params' do
    context 'when template_params is blank' do
      it 'returns the original template_params' do
        result = service.process_template_params(nil)
        expect(result).to be_nil
      end
    end

    context 'when processed_params is blank' do
      let(:template_params) { { 'name' => 'test_template' } }

      it 'returns the original template_params' do
        result = service.process_template_params(template_params)
        expect(result).to eq(template_params)
      end
    end

    context 'with body parameters containing liquid variables' do
      let(:template_params) do
        {
          'name' => 'test_template',
          'namespace' => 'test_namespace',
          'language' => 'en',
          'processed_params' => {
            'body' => {
              'name' => '{{contact.name}}',
              'email' => '{{contact.email}}',
              'static_text' => 'Hello World'
            }
          }
        }
      end

      it 'processes liquid variables in body parameters' do
        result = service.process_template_params(template_params)
        contact_drop_name = ContactDrop.new(contact).name

        expect(result['processed_params']['body']['name']).to eq(contact_drop_name)
        expect(result['processed_params']['body']['email']).to eq(contact.email)
        expect(result['processed_params']['body']['static_text']).to eq('Hello World')
      end

      it 'does not modify the original template_params' do
        original_name_value = template_params['processed_params']['body']['name']
        service.process_template_params(template_params)

        expect(template_params['processed_params']['body']['name']).to eq(original_name_value)
      end
    end

    context 'with header parameters containing liquid variables' do
      let(:template_params) do
        {
          'name' => 'test_template',
          'processed_params' => {
            'header' => {
              'media_url' => 'https://example.com/{{contact.name}}.jpg',
              'media_name' => '{{contact.name}}_document.pdf'
            }
          }
        }
      end

      it 'processes liquid variables in header parameters' do
        result = service.process_template_params(template_params)
        contact_drop_name = ContactDrop.new(contact).name

        expect(result['processed_params']['header']['media_url']).to eq("https://example.com/#{contact_drop_name}.jpg")
        expect(result['processed_params']['header']['media_name']).to eq("#{contact_drop_name}_document.pdf")
      end
    end

    context 'with button parameters containing liquid variables' do
      let(:template_params) do
        {
          'name' => 'test_template',
          'processed_params' => {
            'buttons' => [
              { 'type' => 'url', 'parameter' => '{{contact.email}}' },
              { 'type' => 'copy_code', 'parameter' => 'CODE-{{contact.name}}' }
            ]
          }
        }
      end

      it 'processes liquid variables in button parameters' do
        result = service.process_template_params(template_params)
        contact_drop_name = ContactDrop.new(contact).name

        expect(result['processed_params']['buttons'][0]['parameter']).to eq(contact.email)
        expect(result['processed_params']['buttons'][1]['parameter']).to eq("CODE-#{contact_drop_name}")
      end
    end

    context 'with footer parameters containing liquid variables' do
      let(:template_params) do
        {
          'name' => 'test_template',
          'processed_params' => {
            'footer' => {
              'text' => 'From {{agent.name}} at {{account.name}}'
            }
          }
        }
      end

      it 'processes liquid variables in footer parameters' do
        result = service.process_template_params(template_params)
        agent_drop_name = UserDrop.new(agent).name

        expect(result['processed_params']['footer']['text']).to eq("From #{agent_drop_name} at #{account.name}")
      end
    end

    context 'with multiple liquid variables across different sections' do
      let(:template_params) do
        {
          'name' => 'test_template',
          'processed_params' => {
            'body' => {
              'greeting' => 'Hello {{contact.name}}',
              'agent' => 'Your agent is {{agent.name}}'
            },
            'header' => {
              'media_name' => '{{contact.name}}_file.pdf'
            },
            'buttons' => [
              { 'parameter' => '{{contact.email}}' }
            ],
            'footer' => {
              'text' => '{{inbox.name}}'
            }
          }
        }
      end

      it 'processes all liquid variables correctly' do
        result = service.process_template_params(template_params)
        contact_drop_name = ContactDrop.new(contact).name
        agent_drop_name = UserDrop.new(agent).name

        expect(result['processed_params']['body']['greeting']).to eq("Hello #{contact_drop_name}")
        expect(result['processed_params']['body']['agent']).to eq("Your agent is #{agent_drop_name}")
        expect(result['processed_params']['header']['media_name']).to eq("#{contact_drop_name}_file.pdf")
        expect(result['processed_params']['buttons'][0]['parameter']).to eq(contact.email)
        expect(result['processed_params']['footer']['text']).to eq(inbox.name)
      end
    end

    context 'with blank or nil values' do
      let(:template_params) do
        {
          'name' => 'test_template',
          'processed_params' => {
            'body' => {
              'name' => nil,
              'email' => '',
              'valid' => '{{contact.name}}'
            }
          }
        }
      end

      it 'handles blank values gracefully' do
        result = service.process_template_params(template_params)
        contact_drop_name = ContactDrop.new(contact).name

        expect(result['processed_params']['body']['name']).to be_nil
        expect(result['processed_params']['body']['email']).to eq('')
        expect(result['processed_params']['body']['valid']).to eq(contact_drop_name)
      end
    end

    context 'with custom attributes' do
      let(:contact) do
        create(:contact, account: account, name: 'John Doe',
                         custom_attributes: { 'company' => 'Acme Inc', 'plan' => 'Premium' })
      end
      let(:template_params) do
        {
          'name' => 'test_template',
          'processed_params' => {
            'body' => {
              'company' => '{{contact.custom_attribute.company}}',
              'plan' => '{{contact.custom_attribute.plan}}'
            }
          }
        }
      end

      it 'processes custom attribute liquid variables' do
        result = service.process_template_params(template_params)

        expect(result['processed_params']['body']['company']).to eq('Acme Inc')
        expect(result['processed_params']['body']['plan']).to eq('Premium')
      end
    end

    context 'with invalid liquid syntax' do
      let(:template_params) do
        {
          'name' => 'test_template',
          'processed_params' => {
            'body' => {
              'invalid' => '{{contact.name missing braces'
            }
          }
        }
      end

      it 'returns original value when liquid parsing fails' do
        result = service.process_template_params(template_params)

        expect(result['processed_params']['body']['invalid']).to eq('{{contact.name missing braces')
      end
    end

    context 'with legacy flat hash processed_params' do
      let(:template_params) do
        {
          'name' => 'legacy_template',
          'processed_params' => {
            '1' => '{{contact.name}}',
            '2' => '{{contact.email}}',
            '3' => 'Hello World'
          }
        }
      end

      it 'processes liquid variables in legacy hash values' do
        result = service.process_template_params(template_params)
        contact_drop_name = ContactDrop.new(contact).name

        expect(result['processed_params']['1']).to eq(contact_drop_name)
        expect(result['processed_params']['2']).to eq(contact.email)
        expect(result['processed_params']['3']).to eq('Hello World')
      end
    end

    context 'with legacy array processed_params' do
      let(:template_params) do
        {
          'name' => 'legacy_template',
          'processed_params' => ['{{contact.name}}', '{{contact.email}}', 'Hello World']
        }
      end

      it 'processes liquid variables in legacy array values' do
        result = service.process_template_params(template_params)
        contact_drop_name = ContactDrop.new(contact).name

        expect(result['processed_params']).to eq([contact_drop_name, contact.email, 'Hello World'])
      end
    end
  end
end
