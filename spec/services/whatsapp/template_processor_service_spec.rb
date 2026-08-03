require 'rails_helper'

describe Whatsapp::TemplateProcessorService do
  subject(:processed_components) do
    described_class.new(channel: channel, template_params: template_params).call.last
  end

  let(:channel) { instance_double(Channel::Whatsapp, message_templates: [template]) }
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
end
