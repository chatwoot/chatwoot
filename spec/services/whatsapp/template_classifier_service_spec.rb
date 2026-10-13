require 'rails_helper'

describe Whatsapp::TemplateClassifierService do
  subject(:result) { described_class.new(template).classified_template }

  let(:template) do
    {
      'name' => 'shipping_update',
      'language' => 'en_US',
      'status' => 'APPROVED',
      'category' => 'UTILITY',
      'parameter_format' => 'POSITIONAL',
      'components' => components
    }
  end

  context 'with a parameterless ordinary template' do
    let(:components) { [{ 'type' => 'BODY', 'text' => 'Your shipment is ready.' }] }

    it 'classifies it as sendable without changing the synchronized template' do
      original = template.deep_dup

      expect(result).to include('classification' => 'sendable', 'classification_reason' => nil, 'required_parameters' => [])
      expect(template).to eq(original)
    end
  end

  context 'with supported parameters' do
    let(:components) do
      [
        { 'type' => 'BODY', 'text' => 'Order {{1}} for {{2}}' },
        {
          'type' => 'BUTTONS',
          'buttons' => [
            { 'type' => 'PHONE_NUMBER', 'text' => 'Call', 'phone_number' => '+15555550123' },
            { 'type' => 'URL', 'text' => 'Track', 'url' => 'https://example.com/{{1}}' }
          ]
        }
      ]
    end

    it 'describes ordered values and the synchronized provider button index' do
      expect(result['classification']).to eq('sendable')
      expect(result['required_parameters']).to include(
        include('component' => 'body', 'key' => '1', 'position' => 0),
        include('component' => 'body', 'key' => '2', 'position' => 1),
        include('component' => 'buttons', 'kind' => 'url', 'button_index' => 1)
      )
    end
  end

  context 'with a renderable shape that has no input adapter' do
    let(:components) { [{ 'type' => 'FOOTER', 'text' => 'Reference {{1}}' }] }

    it 'classifies it as preview only with a stable reason' do
      expect(result).to include(
        'classification' => 'preview_only',
        'classification_reason' => 'parameter_adapter_unavailable'
      )
    end
  end

  context 'with an excluded product shape' do
    let(:components) { [{ 'type' => 'CAROUSEL', 'cards' => [] }] }

    it 'classifies it as unsupported' do
      expect(result).to include(
        'classification' => 'unsupported',
        'classification_reason' => 'unsupported_by_linoo_version'
      )
    end
  end

  context 'with no synchronized components' do
    let(:components) { [] }

    it 'classifies the unknown shape as unsupported' do
      expect(result).to include(
        'classification' => 'unsupported',
        'classification_reason' => 'unsupported_by_linoo_version'
      )
    end
  end

  context 'with an authentication template' do
    let(:components) { [{ 'type' => 'BODY', 'text' => '123456' }] }

    before { template['category'] = 'AUTHENTICATION' }

    it 'does not make the excluded shape sendable merely because it has no parameters' do
      expect(result['classification']).to eq('unsupported')
    end
  end
end
