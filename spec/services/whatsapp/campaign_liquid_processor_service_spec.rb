require 'rails_helper'

RSpec.describe Whatsapp::CampaignLiquidProcessorService do
  let(:account) { create(:account) }
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let!(:inbox) { whatsapp_channel.inbox }
  let(:campaign) { create(:campaign, inbox: inbox, account: account) }
  let(:contact) do
    create(:contact,
           account: account,
           name: 'John Doe',
           email: 'john@example.com',
           phone_number: '+1234567890',
           custom_attributes: { customer_type: 'premium', membership_level: 'gold' })
  end

  let(:service) { described_class.new(campaign: campaign, contact: contact) }

  describe '#call' do
    context 'when template_params is blank' do
      it 'returns the original template_params' do
        result = service.call(nil)
        expect(result).to be_nil

        result = service.call({})
        expect(result).to eq({})
      end
    end

    context 'when template_params has no processed_params' do
      let(:template_params) { { 'name' => 'test_template' } }

      it 'returns the original template_params' do
        result = service.call(template_params)
        expect(result).to eq(template_params)
      end
    end

    context 'when template_params contains liquid variables' do
      let(:template_params) do
        {
          'name' => 'greet_template',
          'category' => 'MARKETING',
          'language' => 'en',
          'processed_params' => {
            'body' => {
              'customer_name' => '{{contact.name}}',
              'customer_email' => '{{contact.email}}'
            }
          }
        }
      end

      it 'processes liquid variables in template_params' do
        result = service.call(template_params)

        expect(result['processed_params']['body']['customer_name']).to eq('John Doe')
        expect(result['processed_params']['body']['customer_email']).to eq('john@example.com')
      end

      it 'preserves non-liquid content' do
        result = service.call(template_params)

        expect(result['name']).to eq('greet_template')
        expect(result['category']).to eq('MARKETING')
        expect(result['language']).to eq('en')
      end

      it 'does not modify the original template_params' do
        original_params = template_params.deep_dup
        service.call(template_params)

        expect(template_params).to eq(original_params)
      end
    end

    context 'when template_params contains nested structures' do
      let(:template_params) do
        {
          'name' => 'complex_template',
          'processed_params' => {
            'header' => {
              'media_url' => 'https://example.com/{{contact.name}}.jpg'
            },
            'body' => {
              'customer_name' => '{{contact.name}}',
              'account_name' => '{{account.name}}'
            },
            'footer' => {
              'company_info' => 'Contact {{inbox.name}}'
            },
            'buttons' => [
              { 'type' => 'url', 'parameter' => 'https://portal.com/{{contact.name}}' },
              { 'type' => 'text', 'parameter' => 'Hello {{contact.name}}!' }
            ]
          }
        }
      end

      it 'processes liquid variables in nested hash structures' do
        result = service.call(template_params)

        expect(result['processed_params']['header']['media_url']).to eq('https://example.com/John Doe.jpg')
        expect(result['processed_params']['body']['customer_name']).to eq('John Doe')
        expect(result['processed_params']['body']['account_name']).to eq(account.name)
        expect(result['processed_params']['footer']['company_info']).to eq("Contact #{inbox.name}")
      end

      it 'processes liquid variables in array elements' do
        result = service.call(template_params)

        buttons = result['processed_params']['buttons']
        expect(buttons[0]['parameter']).to eq('https://portal.com/John Doe')
        expect(buttons[1]['parameter']).to eq('Hello John Doe!')
      end
    end

    context 'when template_params contains custom attributes' do
      let(:template_params) do
        {
          'name' => 'custom_attr_template',
          'processed_params' => {
            'body' => {
              'customer_type' => '{{contact.custom_attribute.customer_type}}',
              'membership_level' => '{{contact.custom_attribute.membership_level}}'
            }
          }
        }
      end

      it 'processes custom attributes correctly' do
        result = service.call(template_params)

        expect(result['processed_params']['body']['customer_type']).to eq('premium')
        expect(result['processed_params']['body']['membership_level']).to eq('gold')
      end
    end

    context 'when template_params contains liquid filters' do
      let(:template_params) do
        {
          'name' => 'filter_template',
          'processed_params' => {
            'body' => {
              'customer_email' => '{{ contact.email | default: "no-email@example.com" }}',
              'customer_name_upper' => '{{ contact.name | upcase }}'
            }
          }
        }
      end

      it 'processes liquid filters correctly' do
        result = service.call(template_params)

        expect(result['processed_params']['body']['customer_email']).to eq('john@example.com')
        expect(result['processed_params']['body']['customer_name_upper']).to eq('JOHN DOE')
      end

      context 'when contact email is nil' do
        before { contact.update!(email: nil) }

        it 'uses default filter value' do
          result = service.call(template_params)

          expect(result['processed_params']['body']['customer_email']).to eq('no-email@example.com')
        end
      end
    end

    context 'when template_params contains invalid liquid syntax' do
      let(:template_params) do
        {
          'name' => 'broken_template',
          'processed_params' => {
            'body' => {
              'broken_liquid' => '{{contact.name} invalid}',
              'valid_liquid' => '{{contact.name}}'
            }
          }
        }
      end

      it 'handles broken liquid gracefully' do
        result = service.call(template_params)

        expect(result['processed_params']['body']['broken_liquid']).to eq('{{contact.name} invalid}')
        expect(result['processed_params']['body']['valid_liquid']).to eq('John Doe')
      end
    end
  end
end
