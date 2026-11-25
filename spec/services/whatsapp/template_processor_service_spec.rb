require 'rails_helper'

describe Whatsapp::TemplateProcessorService do
  describe 'header parameters built from the template sample' do
    subject(:processed_parameters) { described_class.new(channel: channel, template_params: template_params).call.last }

    let(:sample_url) { 'https://scontent.whatsapp.net/v/t61.29466-34/sample_n.jpg?ccb=1-7&oh=01_Q5Aa&oe=6AA7FF50' }
    let(:template) do
      {
        'name' => 'promo',
        'status' => 'APPROVED',
        'language' => 'pt_BR',
        'category' => 'MARKETING',
        'components' => [
          { 'type' => 'HEADER', 'format' => 'IMAGE', 'example' => { 'header_handle' => [sample_url] } },
          { 'text' => 'Olá {{1}}', 'type' => 'BODY' }
        ]
      }
    end
    let(:channel) do
      create(:channel_whatsapp, provider: 'whatsapp_cloud', message_templates: [template], validate_provider_config: false, sync_templates: false)
    end
    let(:template_params) do
      {
        'name' => 'promo',
        'language' => 'pt_BR',
        'processed_params' => {
          'body' => { '1' => 'Ana' },
          'header' => { 'media_url' => media_url, 'media_type' => 'image' }
        }
      }
    end

    context "when the agent sends the template's own sample media" do
      let(:media_url) { sample_url }

      # That URL is hosted on Meta's CDN, which answers 403 to Meta's own media fetcher, so it can only
      # be delivered as an uploaded media id.
      it 'uploads it and addresses it by id' do
        allow(Whatsapp::TemplateSampleMediaService).to receive(:new)
          .with(channel: channel, url: sample_url)
          .and_return(instance_double(Whatsapp::TemplateSampleMediaService, media_id: 'uploaded_id'))

        expect(processed_parameters).to include(
          { type: 'header', parameters: [{ type: 'image', image: { id: 'uploaded_id' } }] }
        )
      end
    end

    # A scheduled message or a campaign stores the sample URL at compose time. By the time it fires, the
    # sync has refreshed the template and Meta has re-signed the handle, so the stored string no longer
    # matches character for character.
    context 'when the stored sample URL carries a signature that has since rotated' do
      let(:media_url) { 'https://scontent.whatsapp.net/v/t61.29466-34/sample_n.jpg?ccb=1-7&oh=00_OldSig&oe=6A000000' }

      it 'uploads the handle the template carries now' do
        allow(Whatsapp::TemplateSampleMediaService).to receive(:new)
          .with(channel: channel, url: sample_url)
          .and_return(instance_double(Whatsapp::TemplateSampleMediaService, media_id: 'uploaded_id'))

        expect(processed_parameters).to include(
          { type: 'header', parameters: [{ type: 'image', image: { id: 'uploaded_id' } }] }
        )
      end
    end

    context 'when the agent supplies their own URL' do
      let(:media_url) { 'https://cdn.example.com/promo.jpg' }

      it 'sends it as a link' do
        expect(Whatsapp::TemplateSampleMediaService).not_to receive(:new)

        expect(processed_parameters).to include(
          { type: 'header', parameters: [{ type: 'image', image: { link: media_url } }] }
        )
      end
    end

    context 'when the provider is not whatsapp_cloud' do
      let(:media_url) { sample_url }
      let(:channel) { create(:channel_whatsapp, message_templates: [template], validate_provider_config: false, sync_templates: false) }

      it 'sends the sample media as a link, since only the Cloud API exposes a media store' do
        expect(Whatsapp::TemplateSampleMediaService).not_to receive(:new)

        expect(processed_parameters).to include(
          { type: 'header', parameters: [{ type: 'image', image: { link: sample_url } }] }
        )
      end
    end
  end

  describe 'component parameters' do
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

    context 'with a static button before a dynamic button' do
      let(:template) do
        {
          'name' => 'offer', 'language' => 'en_US', 'status' => 'APPROVED',
          'components' => [
            { 'type' => 'BODY', 'text' => 'Your offer' },
            { 'type' => 'BUTTONS', 'buttons' => [{ 'type' => 'QUICK_REPLY', 'text' => 'Thanks' }, { 'type' => 'COPY_CODE' }] }
          ]
        }
      end
      let(:template_params) do
        {
          'name' => 'offer', 'language' => 'en_US',
          'processed_params' => { 'buttons' => [nil, { 'type' => 'copy_code', 'parameter' => 'WELCOME' }] }
        }
      end

      it 'preserves the dynamic button index through normalization and payload generation' do
        expect(processed_components).to eq([
                                             { type: 'button', sub_type: 'copy_code', index: 1,
                                               parameters: [{ type: 'coupon_code', coupon_code: 'WELCOME' }] }
                                           ])
      end
    end
  end
end
