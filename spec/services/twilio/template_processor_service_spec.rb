require 'rails_helper'

RSpec.describe Twilio::TemplateProcessorService do
  subject(:processor_service) { described_class.new(channel: twilio_channel, template_params: template_params, message: message) }

  let!(:account) { create(:account) }
  let!(:twilio_channel) { create(:channel_twilio_sms, medium: :whatsapp, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:inbox) { create(:inbox, channel: twilio_channel, account: account) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let!(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox) }
  let!(:message) { create(:message, conversation: conversation, account: account) }

  let(:content_templates) do
    {
      'templates' => [
        {
          'content_sid' => 'HX123456789',
          'friendly_name' => 'hello_world',
          'language' => 'en',
          'status' => 'approved',
          'template_type' => 'text',
          'media_type' => nil,
          'variables' => {},
          'category' => 'utility',
          'body' => 'Hello World!'
        },
        {
          'content_sid' => 'HX987654321',
          'friendly_name' => 'greet',
          'language' => 'en',
          'status' => 'approved',
          'template_type' => 'text',
          'media_type' => nil,
          'variables' => { '1' => 'John' },
          'category' => 'utility',
          'body' => 'Hello {{1}}!'
        },
        {
          'content_sid' => 'HX555666777',
          'friendly_name' => 'product_showcase',
          'language' => 'en',
          'status' => 'approved',
          'template_type' => 'media',
          'media_type' => 'image',
          'variables' => { '1' => 'https://example.com/image.jpg', '2' => 'iPhone', '3' => '$999' },
          'category' => 'marketing',
          'body' => 'Check out {{2}} for {{3}}'
        },
        {
          'content_sid' => 'HX111222333',
          'friendly_name' => 'welcome_message',
          'language' => 'en_US',
          'status' => 'approved',
          'template_type' => 'quick_reply',
          'media_type' => nil,
          'variables' => {},
          'category' => 'utility',
          'body' => 'Welcome! How can we help?'
        },
        {
          'content_sid' => 'HX444555666',
          'friendly_name' => 'order_status',
          'language' => 'es',
          'status' => 'approved',
          'template_type' => 'text',
          'media_type' => nil,
          'variables' => { '1' => 'Juan', '2' => 'ORD123' },
          'category' => 'utility',
          'body' => 'Hola {{1}}, tu pedido {{2}} está confirmado'
        }
      ]
    }
  end

  before do
    twilio_channel.update!(content_templates: content_templates)
  end

  describe '#call' do
    context 'with blank template_params' do
      let(:template_params) { nil }

      it 'returns nil values' do
        result = processor_service.call

        expect(result).to eq([nil, nil])
      end
    end

    context 'with empty template_params' do
      let(:template_params) { {} }

      it 'returns nil values' do
        result = processor_service.call

        expect(result).to eq([nil, nil])
      end
    end

    context 'with template not found' do
      let(:template_params) do
        {
          'name' => 'nonexistent_template',
          'language' => 'en'
        }
      end

      it 'returns nil values' do
        result = processor_service.call

        expect(result).to eq([nil, nil])
      end
    end

    context 'with text templates' do
      context 'with simple text template (no variables)' do
        let(:template_params) do
          {
            'name' => 'hello_world',
            'language' => 'en'
          }
        end

        it 'returns content_sid and empty variables' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX123456789')
          expect(content_variables).to eq({})
        end
      end

      context 'with text template using processed_params format' do
        let(:template_params) do
          {
            'name' => 'greet',
            'language' => 'en',
            'processed_params' => {
              '1' => 'Alice',
              '2' => 'Premium User'
            }
          }
        end

        it 'processes key-value parameters correctly' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX987654321')
          expect(content_variables).to eq({
                                            '1' => 'Alice',
                                            '2' => 'Premium User'
                                          })
        end
      end

      context 'with text template using WhatsApp Cloud API format' do
        let(:template_params) do
          {
            'name' => 'greet',
            'language' => 'en',
            'parameters' => [
              {
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'Bob' }
                ]
              }
            ]
          }
        end

        it 'processes WhatsApp format parameters correctly' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX987654321')
          expect(content_variables).to eq({ '1' => 'Bob' })
        end
      end

      context 'with multiple body parameters' do
        let(:template_params) do
          {
            'name' => 'greet',
            'language' => 'en',
            'parameters' => [
              {
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'Charlie' },
                  { 'type' => 'text', 'text' => 'VIP Member' }
                ]
              }
            ]
          }
        end

        it 'processes multiple parameters with sequential indexing' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX987654321')
          expect(content_variables).to eq({
                                            '1' => 'Charlie',
                                            '2' => 'VIP Member'
                                          })
        end
      end
    end

    context 'with quick reply templates' do
      let(:template_params) do
        {
          'name' => 'welcome_message',
          'language' => 'en_US'
        }
      end

      it 'processes quick reply templates like text templates' do
        content_sid, content_variables = processor_service.call

        expect(content_sid).to eq('HX111222333')
        expect(content_variables).to eq({})
      end

      context 'with quick reply template having body parameters' do
        let(:template_params) do
          {
            'name' => 'welcome_message',
            'language' => 'en_US',
            'parameters' => [
              {
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'Diana' }
                ]
              }
            ]
          }
        end

        it 'processes body parameters for quick reply templates' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX111222333')
          expect(content_variables).to eq({ '1' => 'Diana' })
        end
      end
    end

    context 'with media templates' do
      context 'with media template using processed_params format' do
        let(:template_params) do
          {
            'name' => 'product_showcase',
            'language' => 'en',
            'processed_params' => {
              '1' => 'https://cdn.example.com/product.jpg',
              '2' => 'MacBook Pro',
              '3' => '$2499'
            }
          }
        end

        it 'processes key-value parameters for media templates' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX555666777')
          expect(content_variables).to eq({
                                            '1' => 'https://cdn.example.com/product.jpg',
                                            '2' => 'MacBook Pro',
                                            '3' => '$2499'
                                          })
        end
      end

      context 'with media template using WhatsApp Cloud API format' do
        let(:template_params) do
          {
            'name' => 'product_showcase',
            'language' => 'en',
            'parameters' => [
              {
                'type' => 'header',
                'parameters' => [
                  {
                    'type' => 'image',
                    'image' => { 'link' => 'https://example.com/product-image.jpg' }
                  }
                ]
              },
              {
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'Samsung Galaxy' },
                  { 'type' => 'text', 'text' => '$899' }
                ]
              }
            ]
          }
        end

        it 'processes media header and body parameters correctly' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX555666777')
          expect(content_variables).to eq({
                                            '1' => 'https://example.com/product-image.jpg',
                                            '2' => 'Samsung Galaxy',
                                            '3' => '$899'
                                          })
        end
      end

      context 'with video media template' do
        let(:template_params) do
          {
            'name' => 'product_showcase',
            'language' => 'en',
            'parameters' => [
              {
                'type' => 'header',
                'parameters' => [
                  {
                    'type' => 'video',
                    'video' => { 'link' => 'https://example.com/demo.mp4' }
                  }
                ]
              },
              {
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'Product Demo' }
                ]
              }
            ]
          }
        end

        it 'processes video media parameters correctly' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX555666777')
          expect(content_variables).to eq({
                                            '1' => 'https://example.com/demo.mp4',
                                            '2' => 'Product Demo'
                                          })
        end
      end

      context 'with document media template' do
        let(:template_params) do
          {
            'name' => 'product_showcase',
            'language' => 'en',
            'parameters' => [
              {
                'type' => 'header',
                'parameters' => [
                  {
                    'type' => 'document',
                    'document' => { 'link' => 'https://example.com/brochure.pdf' }
                  }
                ]
              },
              {
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'Product Brochure' }
                ]
              }
            ]
          }
        end

        it 'processes document media parameters correctly' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX555666777')
          expect(content_variables).to eq({
                                            '1' => 'https://example.com/brochure.pdf',
                                            '2' => 'Product Brochure'
                                          })
        end
      end

      context 'with header parameter without media link' do
        let(:template_params) do
          {
            'name' => 'product_showcase',
            'language' => 'en',
            'parameters' => [
              {
                'type' => 'header',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'Header Text' }
                ]
              },
              {
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'Body Text' }
                ]
              }
            ]
          }
        end

        it 'skips header without media and processes body parameters' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX555666777')
          expect(content_variables).to eq({ '1' => 'Body Text' })
        end
      end

      context 'with mixed component types' do
        let(:template_params) do
          {
            'name' => 'product_showcase',
            'language' => 'en',
            'parameters' => [
              {
                'type' => 'header',
                'parameters' => [
                  {
                    'type' => 'image',
                    'image' => { 'link' => 'https://example.com/header.jpg' }
                  }
                ]
              },
              {
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'text' => 'First param' },
                  { 'type' => 'text', 'text' => 'Second param' }
                ]
              },
              {
                'type' => 'footer',
                'parameters' => []
              }
            ]
          }
        end

        it 'processes supported components and ignores unsupported ones' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX555666777')
          expect(content_variables).to eq({
                                            '1' => 'https://example.com/header.jpg',
                                            '2' => 'First param',
                                            '3' => 'Second param'
                                          })
        end
      end
    end

    context 'with language matching' do
      context 'with exact language match' do
        let(:template_params) do
          {
            'name' => 'order_status',
            'language' => 'es'
          }
        end

        it 'finds template with exact language match' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX444555666')
          expect(content_variables).to eq({})
        end
      end

      context 'with default language fallback' do
        let(:template_params) do
          {
            'name' => 'hello_world'
            # No language specified, should default to 'en'
          }
        end

        it 'defaults to English when no language specified' do
          content_sid, content_variables = processor_service.call

          expect(content_sid).to eq('HX123456789')
          expect(content_variables).to eq({})
        end
      end
    end

    context 'with unapproved template status' do
      let(:template_params) do
        {
          'name' => 'unapproved_template',
          'language' => 'en'
        }
      end

      before do
        unapproved_template = {
          'content_sid' => 'HX_UNAPPROVED',
          'friendly_name' => 'unapproved_template',
          'language' => 'en',
          'status' => 'pending',
          'template_type' => 'text',
          'variables' => {},
          'body' => 'This is unapproved'
        }

        updated_templates = content_templates['templates'] + [unapproved_template]
        twilio_channel.update!(
          content_templates: { 'templates' => updated_templates }
        )
      end

      it 'ignores templates that are not approved' do
        content_sid, content_variables = processor_service.call

        expect(content_sid).to be_nil
        expect(content_variables).to be_nil
      end
    end

    context 'with unknown template type' do
      let(:template_params) do
        {
          'name' => 'unknown_type',
          'language' => 'en'
        }
      end

      before do
        unknown_template = {
          'content_sid' => 'HX_UNKNOWN',
          'friendly_name' => 'unknown_type',
          'language' => 'en',
          'status' => 'approved',
          'template_type' => 'catalog',
          'variables' => {},
          'body' => 'Catalog template'
        }

        updated_templates = content_templates['templates'] + [unknown_template]
        twilio_channel.update!(
          content_templates: { 'templates' => updated_templates }
        )
      end

      it 'returns empty content variables for unknown template types' do
        content_sid, content_variables = processor_service.call

        expect(content_sid).to eq('HX_UNKNOWN')
        expect(content_variables).to eq({})
      end
    end
  end

  describe 'template finding behavior' do
    context 'with no content_templates' do
      let(:template_params) do
        {
          'name' => 'hello_world',
          'language' => 'en'
        }
      end

      before do
        twilio_channel.update!(content_templates: {})
      end

      it 'returns nil values when content_templates is empty' do
        result = processor_service.call

        expect(result).to eq([nil, nil])
      end
    end

    context 'with nil content_templates' do
      let(:template_params) do
        {
          'name' => 'hello_world',
          'language' => 'en'
        }
      end

      before do
        twilio_channel.update!(content_templates: nil)
      end

      it 'returns nil values when content_templates is nil' do
        result = processor_service.call

        expect(result).to eq([nil, nil])
      end
    end
  end
end
