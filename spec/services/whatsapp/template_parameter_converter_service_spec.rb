require 'rails_helper'

describe Whatsapp::TemplateParameterConverterService do
  let(:template) do
    {
      'name' => 'test_template',
      'language' => 'en',
      'components' => [
        {
          'type' => 'BODY',
          'text' => 'Hello {{1}}, your order {{2}} is ready!'
        }
      ]
    }
  end

  let(:media_template) do
    {
      'name' => 'media_template',
      'language' => 'en',
      'components' => [
        {
          'type' => 'HEADER',
          'format' => 'IMAGE'
        },
        {
          'type' => 'BODY',
          'text' => 'Check out {{1}}!'
        }
      ]
    }
  end

  let(:button_template) do
    {
      'name' => 'button_template',
      'language' => 'en',
      'components' => [
        {
          'type' => 'BODY',
          'text' => 'Visit our website!'
        },
        {
          'type' => 'BUTTONS',
          'buttons' => [
            {
              'type' => 'URL',
              'url' => 'https://example.com/{{1}}'
            },
            {
              'type' => 'COPY_CODE'
            }
          ]
        }
      ]
    }
  end

  describe '#normalize_to_enhanced' do
    context 'when already enhanced format' do
      let(:enhanced_params) do
        {
          'processed_params' => {
            'body' => { '1' => 'John', '2' => 'Order123' }
          }
        }
      end

      it 'returns unchanged' do
        converter = described_class.new(enhanced_params, template)
        result = converter.normalize_to_enhanced
        expect(result).to eq(enhanced_params)
      end
    end

    context 'when legacy array format' do
      let(:legacy_array_params) do
        {
          'processed_params' => %w[John Order123]
        }
      end

      it 'converts to enhanced format' do
        converter = described_class.new(legacy_array_params, template)
        result = converter.normalize_to_enhanced

        expect(result['processed_params']).to eq({
                                                   'body' => { '1' => 'John', '2' => 'Order123' }
                                                 })
        expect(result['format_version']).to eq('legacy')
      end
    end

    context 'when legacy flat hash format' do
      let(:legacy_hash_params) do
        {
          'processed_params' => { '1' => 'John', '2' => 'Order123' }
        }
      end

      it 'converts to enhanced format' do
        converter = described_class.new(legacy_hash_params, template)
        result = converter.normalize_to_enhanced

        expect(result['processed_params']).to eq({
                                                   'body' => { '1' => 'John', '2' => 'Order123' }
                                                 })
        expect(result['format_version']).to eq('legacy')
      end
    end

    context 'when legacy hash with all body parameters' do
      let(:legacy_hash_params) do
        {
          'processed_params' => {
            '1' => 'Product',
            'customer_name' => 'John'
          }
        }
      end

      it 'converts to enhanced format with body only' do
        converter = described_class.new(legacy_hash_params, media_template)
        result = converter.normalize_to_enhanced

        expect(result['processed_params']).to eq({
                                                   'body' => {
                                                     '1' => 'Product',
                                                     'customer_name' => 'John'
                                                   }
                                                 })
        expect(result['format_version']).to eq('legacy')
      end
    end

    context 'when processed_params is nil (parameter-less templates)' do
      let(:nil_params) do
        {
          'processed_params' => nil
        }
      end

      let(:parameterless_template) do
        {
          'name' => 'test_no_params_template',
          'language' => 'en',
          'parameter_format' => 'POSITIONAL',
          'id' => '9876543210987654',
          'status' => 'APPROVED',
          'category' => 'UTILITY',
          'previous_category' => 'MARKETING',
          'sub_category' => 'CUSTOM',
          'components' => [
            {
              'type' => 'BODY',
              'text' => 'Thank you for contacting us! Your request has been processed successfully. Have a great day! 🙂'
            }
          ]
        }
      end

      it 'converts nil to empty enhanced format' do
        converter = described_class.new(nil_params, parameterless_template)
        result = converter.normalize_to_enhanced

        expect(result['processed_params']).to eq({})
        expect(result['format_version']).to eq('legacy')
      end

      it 'does not raise ArgumentError for nil processed_params' do
        expect do
          converter = described_class.new(nil_params, parameterless_template)
          converter.normalize_to_enhanced
        end.not_to raise_error
      end
    end

    context 'when invalid format' do
      let(:invalid_params) do
        {
          'processed_params' => 'invalid_string'
        }
      end

      it 'raises ArgumentError' do
        expect do
          converter = described_class.new(invalid_params, template)
          converter.normalize_to_enhanced
        end.to raise_error(ArgumentError, /Unknown legacy format/)
      end
    end
  end

  describe '#enhanced_format?' do
    it 'returns true for valid enhanced format' do
      enhanced = { 'body' => { '1' => 'test' } }
      converter = described_class.new({}, template)
      expect(converter.send(:enhanced_format?, enhanced)).to be true
    end

    it 'returns false for array' do
      converter = described_class.new({}, template)
      expect(converter.send(:enhanced_format?, ['test'])).to be false
    end

    it 'returns false for flat hash' do
      converter = described_class.new({}, template)
      expect(converter.send(:enhanced_format?, { '1' => 'test' })).to be false
    end

    it 'returns false for invalid structure' do
      invalid = { 'body' => 'not_a_hash' }
      converter = described_class.new({}, template)
      expect(converter.send(:enhanced_format?, invalid)).to be false
    end
  end

  describe 'simplified conversion methods' do
    describe '#convert_legacy_to_enhanced' do
      it 'handles nil processed_params without raising error' do
        converter = described_class.new({}, template)
        result = converter.send(:convert_legacy_to_enhanced, nil, template)
        expect(result).to eq({})
      end

      it 'returns empty hash for parameter-less templates' do
        parameterless_template = {
          'name' => 'no_params_template',
          'language' => 'en',
          'components' => [{ 'type' => 'BODY', 'text' => 'Hello World!' }]
        }

        converter = described_class.new({}, parameterless_template)
        result = converter.send(:convert_legacy_to_enhanced, nil, parameterless_template)
        expect(result).to eq({})
      end
    end

    describe '#convert_array_to_body_params' do
      it 'converts empty array' do
        converter = described_class.new({}, template)
        result = converter.send(:convert_array_to_body_params, [])
        expect(result).to eq({})
      end

      it 'converts array to numbered body parameters' do
        converter = described_class.new({}, template)
        result = converter.send(:convert_array_to_body_params, %w[John Order123])
        expect(result).to eq({ '1' => 'John', '2' => 'Order123' })
      end
    end

    describe '#convert_hash_to_body_params' do
      it 'converts hash to body parameters' do
        converter = described_class.new({}, template)
        result = converter.send(:convert_hash_to_body_params, { 'name' => 'John', 'order' => '123' })
        expect(result).to eq({ 'name' => 'John', 'order' => '123' })
      end
    end
  end
end
