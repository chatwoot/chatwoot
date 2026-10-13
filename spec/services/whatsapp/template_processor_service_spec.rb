require 'rails_helper'

describe Whatsapp::TemplateProcessorService do
  subject(:processed_components) do
    described_class.new(channel: channel, template_params: template_params).call.last
  end

  let(:channel) { instance_double(Channel::Whatsapp, provider: 'whatsapp_cloud', message_templates: [template]) }
  let(:template_params) do
    {
      'name' => template['name'],
      'language' => template['language'],
      'processed_params' => { 'header' => header_params }
    }
  end

  context 'with a positional text header' do
    let(:template) do
      {
        'name' => 'positional_header',
        'language' => 'en_US',
        'status' => 'APPROVED',
        'parameter_format' => 'POSITIONAL',
        'components' => [{ 'type' => 'HEADER', 'format' => 'TEXT', 'text' => 'Welcome {{1}}' }]
      }
    end
    let(:header_params) { { '1' => 'Jane' } }

    it 'builds a positional text parameter' do
      expect(processed_components).to eq([
                                           {
                                             type: 'header',
                                             parameters: [{ type: 'text', text: 'Jane' }]
                                           }
                                         ])
    end
  end

  context 'with a named text header' do
    let(:template) do
      {
        'name' => 'named_header',
        'language' => 'en_US',
        'status' => 'APPROVED',
        'parameter_format' => 'NAMED',
        'components' => [{ 'type' => 'HEADER', 'format' => 'TEXT', 'text' => "Welcome {{#{parameter_name}}}" }]
      }
    end
    let(:header_params) { { parameter_name => 'Jane' } }

    %w[customer_name media_type media_name].each do |name|
      context "when the parameter is #{name}" do
        let(:parameter_name) { name }

        it 'preserves the parameter name' do
          expect(processed_components).to eq([
                                               {
                                                 type: 'header',
                                                 parameters: [{ type: 'text', parameter_name: parameter_name, text: 'Jane' }]
                                               }
                                             ])
        end
      end
    end
  end

  context 'with positional body parameters' do
    let(:template) do
      {
        'name' => 'positional_body',
        'language' => 'en_US',
        'status' => 'APPROVED',
        'parameter_format' => 'POSITIONAL',
        'components' => [{ 'type' => 'BODY', 'text' => '{{1}} / {{2}}' }]
      }
    end
    let(:template_params) do
      {
        'name' => template['name'],
        'language' => template['language'],
        'processed_params' => {
          'body' => {
            '2' => 'Bob',
            '1' => 'Alice'
          }
        }
      }
    end

    it 'orders parameters by their positional key' do
      expect(processed_components).to eq([
                                           {
                                             type: 'body',
                                             parameters: [
                                               { type: 'text', text: 'Alice' },
                                               { type: 'text', text: 'Bob' }
                                             ]
                                           }
                                         ])
    end
  end

  context 'with a media header' do
    let(:template) do
      {
        'name' => 'document_header',
        'language' => 'en_US',
        'status' => 'APPROVED',
        'parameter_format' => 'POSITIONAL',
        'components' => [{ 'type' => 'HEADER', 'format' => 'DOCUMENT' }]
      }
    end
    let(:header_params) do
      {
        'media_url' => 'https://example.com/report.pdf',
        'media_type' => 'document',
        'media_name' => 'report.pdf'
      }
    end

    it 'uses media metadata to build the attachment parameter' do
      expect(processed_components).to eq([
                                           {
                                             type: 'header',
                                             parameters: [
                                               {
                                                 type: 'document',
                                                 document: {
                                                   link: 'https://example.com/report.pdf',
                                                   filename: 'report.pdf'
                                                 }
                                               }
                                             ]
                                           }
                                         ])
    end
  end

  context 'with a parameterless approved template' do
    let(:template) do
      {
        'name' => 'hello_world',
        'language' => 'en_US',
        'status' => 'APPROVED',
        'category' => 'UTILITY',
        'components' => [{ 'type' => 'BODY', 'text' => 'Hello World!' }]
      }
    end
    let(:template_params) { { 'name' => 'hello_world', 'language' => 'en_US', 'processed_params' => {} } }

    it 'uses the synchronized identity and an empty component set' do
      expect(described_class.new(channel: channel, template_params: template_params).call).to eq(
        ['hello_world', nil, 'en_US', []]
      )
    end
  end

  context 'with an identity that differs from the synchronized record' do
    let(:template) do
      {
        'name' => 'hello_world', 'language' => 'en_US', 'status' => 'APPROVED', 'category' => 'UTILITY',
        'components' => [{ 'type' => 'BODY', 'text' => 'Hello World!' }]
      }
    end
    let(:header_params) { {} }

    it 'rejects a language with different casing' do
      template_params['language'] = 'en_us'

      expect { described_class.new(channel: channel, template_params: template_params).call }
        .to raise_error(described_class::ValidationError, 'Template is not an approved synchronized template')
    end
  end

  context 'with incomplete body parameters' do
    let(:template) do
      {
        'name' => 'order_update', 'language' => 'en_US', 'status' => 'APPROVED', 'category' => 'UTILITY',
        'parameter_format' => 'POSITIONAL',
        'components' => [{ 'type' => 'BODY', 'text' => 'Order {{1}} is {{2}}' }]
      }
    end
    let(:template_params) do
      { 'name' => 'order_update', 'language' => 'en_US', 'processed_params' => { 'body' => { '1' => '123' } } }
    end

    it 'rejects missing values' do
      expect { described_class.new(channel: channel, template_params: template_params).call }
        .to raise_error(described_class::ValidationError, /do not match/)
    end
  end

  context 'with positional structured parameters' do
    let(:template) do
      {
        'name' => 'invoice', 'language' => 'en_US', 'status' => 'APPROVED', 'category' => 'UTILITY',
        'parameter_format' => 'POSITIONAL',
        'components' => [{ 'type' => 'BODY', 'text' => 'Total {{1}} on {{2}}' }]
      }
    end
    let(:template_params) do
      {
        'name' => 'invoice', 'language' => 'en_US',
        'processed_params' => {
          'body' => {
            '1' => { 'type' => 'currency', 'fallback_value' => '$12.00', 'code' => 'USD', 'amount_1000' => 12_000 },
            '2' => { 'type' => 'date_time', 'fallback_value' => 'October 12', 'day_of_month' => 12, 'month' => 10, 'year' => 2026 }
          }
        }
      }
    end

    it 'retains values supported by the existing parameter builder' do
      expect(processed_components).to eq([
                                           {
                                             type: 'body',
                                             parameters: [
                                               { type: 'currency', currency: { fallback_value: '$12.00', code: 'USD', amount_1000: 12_000 } },
                                               {
                                                 type: 'date_time',
                                                 date_time: {
                                                   fallback_value: 'October 12', day_of_week: nil, day_of_month: 12, month: 10, year: 2026
                                                 }
                                               }
                                             ]
                                           }
                                         ])
    end
  end

  context 'with dynamic URL buttons separated by a static button' do
    let(:template) do
      {
        'name' => 'track_orders', 'language' => 'en_US', 'status' => 'APPROVED', 'category' => 'UTILITY',
        'components' => [
          {
            'type' => 'BUTTONS',
            'buttons' => [
              { 'type' => 'PHONE_NUMBER', 'phone_number' => '+15555550123' },
              { 'type' => 'URL', 'url' => 'https://example.com/orders/{{first}}' },
              { 'type' => 'URL', 'url' => 'https://example.com/orders/{{second}}' }
            ]
          }
        ]
      }
    end
    let(:template_params) do
      {
        'name' => 'track_orders', 'language' => 'en_US',
        'processed_params' => {
          'buttons' => [
            nil,
            { 'type' => 'url', 'parameter' => 'A', 'url' => 'https://example.com/orders/{{first}}', 'variables' => ['first'] },
            { 'type' => 'url', 'parameter' => 'B', 'url' => 'https://example.com/orders/{{second}}', 'variables' => ['second'] }
          ]
        }
      }
    end

    it 'uses synchronized indexes for the provider components' do
      expect(processed_components.pluck(:index)).to eq([1, 2])
    end

    it 'maps compact dynamic parameters onto synchronized indexes' do
      template_params['processed_params']['buttons'].compact!

      expect(processed_components.pluck(:index)).to eq([1, 2])
    end

    it 'rejects swapped wrapper metadata' do
      template_params['processed_params']['buttons'][1], template_params['processed_params']['buttons'][2] =
        template_params['processed_params']['buttons'][2], template_params['processed_params']['buttons'][1]

      expect { described_class.new(channel: channel, template_params: template_params).call }
        .to raise_error(described_class::ValidationError, /definition does not match/)
    end
  end

  context 'with a 360dialog channel' do
    let(:channel) { instance_double(Channel::Whatsapp, provider: 'default', message_templates: [template]) }
    let(:template) do
      {
        'name' => 'legacy_template', 'language' => 'en_US', 'status' => 'APPROVED',
        'components' => [
          { 'type' => 'BODY', 'text' => '{{1}} {{2}}' },
          {
            'type' => 'BUTTONS',
            'buttons' => [
              { 'type' => 'PHONE_NUMBER', 'phone_number' => '+15555550123' },
              { 'type' => 'URL', 'url' => 'https://example.com/{{1}}' }
            ]
          }
        ]
      }
    end
    let(:template_params) do
      {
        'name' => 'LEGACY_TEMPLATE', 'namespace' => 'client-namespace', 'language' => 'en_us',
        'processed_params' => {
          'body' => { '1' => '', '2' => 'kept' },
          'buttons' => [{ 'type' => 'url', 'parameter' => 'legacy' }]
        }
      }
    end

    it 'preserves legacy identity, namespace, case-insensitive lookup, and blank omission' do
      expect(described_class.new(channel: channel, template_params: template_params).call).to eq(
        [
          'LEGACY_TEMPLATE',
          'client-namespace',
          'en_us',
          [
            { type: 'body', parameters: [{ type: 'text', text: 'kept' }] },
            { type: 'button', sub_type: 'url', index: 0, parameters: [{ type: 'text', text: 'legacy' }] }
          ]
        ]
      )
    end
  end
end
