require 'rails_helper'

RSpec.describe Whatsapp::TemplateCreatorService do
  let(:whatsapp_cloud_channel) do
    instance_double(
      Channel::Whatsapp,
      provider_config: {
        'business_account_id' => '123456789',
        'api_key' => 'token'
      }
    )
  end

  describe '#build_request_body' do
    it 'sends named body parameter examples for named Meta variables' do
      channel = instance_double(Channel::Whatsapp, provider_config: {})
      service = described_class.new(channel)

      request_body = service.send(
        :build_request_body,
        name: 'alerta_movimentacao_processual_v1',
        language: 'pt_BR',
        category: 'UTILITY',
        body_text: '{{lista_processos}}'
      )

      body_component = request_body[:components].find { |component| component[:type] == 'BODY' }

      expect(request_body[:parameter_format]).to eq('NAMED')
      expect(body_component[:example]).to eq(
        body_text_named_params: [
          {
            param_name: 'lista_processos',
            example: Whatsapp::TemplateVariableExamples.fetch('lista_processos')
          }
        ]
      )
    end

    it 'builds media header and footer components for image-header templates' do
      channel = instance_double(Channel::Whatsapp, provider_config: {})
      service = described_class.new(channel)

      request_body = service.send(
        :build_request_body,
        name: 'alerta_movimentacao_processual_v2',
        language: 'pt_BR',
        category: 'UTILITY',
        parameter_format: 'NAMED',
        allow_category_change: false,
        header_format: 'IMAGE',
        header_handle: '4::header_handle',
        body_text: '{{lista_processos}}',
        footer_text: 'JusMonitorIA — O Futuro da Inteligência Jurídica®'
      )

      expect(request_body).to include(
        name: 'alerta_movimentacao_processual_v2',
        parameter_format: 'NAMED',
        allow_category_change: false
      )
      expect(request_body[:components]).to include(
        {
          type: 'HEADER',
          format: 'IMAGE',
          example: { header_handle: ['4::header_handle'] }
        },
        {
          type: 'FOOTER',
          text: 'JusMonitorIA — O Futuro da Inteligência Jurídica®'
        }
      )
    end
  end

  describe '#create_template' do
    it 'returns Meta user-facing error details when template creation fails' do
      service = described_class.new(whatsapp_cloud_channel)
      stub_request(:post, 'https://graph.facebook.com/v22.0/123456789/message_templates')
        .to_return(
          status: 400,
          body: {
            error: {
              message: 'Invalid parameter',
              code: 100,
              error_subcode: 2_388_023,
              error_user_title: 'O idioma do modelo de mensagem está sendo excluído',
              error_user_msg: 'Tente novamente em menos de 1 minuto.',
              fbtrace_id: 'trace-123'
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = service.create_template(
        name: 'alerta_movimentacao_processual_v1',
        language: 'pt_BR',
        category: 'UTILITY',
        body_text: '{{lista_processos}}'
      )

      expect(result).to include(
        success: false,
        error: 'Tente novamente em menos de 1 minuto.',
        meta_error_subcode: 2_388_023,
        meta_error_title: 'O idioma do modelo de mensagem está sendo excluído',
        meta_error_message: 'Invalid parameter',
        meta_fbtrace_id: 'trace-123'
      )
    end

    it 'uploads image header media before submitting a template with media header' do
      service = described_class.new(whatsapp_cloud_channel)
      stub_media_header_upload(whatsapp_cloud_channel)
      stub_meta_template_creation_with_media_header

      result = service.create_template(
        name: 'alerta_movimentacao_processual_v2',
        language: 'pt_BR',
        category: 'UTILITY',
        parameter_format: 'NAMED',
        allow_category_change: false,
        header_format: 'IMAGE',
        header_media_url: 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png',
        body_text: '{{lista_processos}}',
        footer_text: 'JusMonitorIA — O Futuro da Inteligência Jurídica®'
      )

      expect(result).to include(
        success: true,
        template_id: 'template_456',
        template_name: 'alerta_movimentacao_processual_v2',
        parameter_format: 'NAMED'
      )
    end
  end

  def stub_media_header_upload(channel)
    media_service = instance_double(Whatsapp::TemplateMediaHeaderHandleService)

    allow(Whatsapp::TemplateMediaHeaderHandleService).to receive(:new).with(channel).and_return(media_service)
    allow(media_service).to receive(:generate).with(
      media_url: 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png',
      file_name: nil
    ).and_return(success: true, header_handle: '4::header_handle')
  end

  def stub_meta_template_creation_with_media_header
    stub_request(:post, 'https://graph.facebook.com/v22.0/123456789/message_templates')
      .with { |request| media_template_payload?(JSON.parse(request.body)) }
      .to_return(
        status: 200,
        body: { id: 'template_456', category: 'UTILITY', parameter_format: 'NAMED' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def media_template_payload?(body)
    header = body['components'].find { |component| component['type'] == 'HEADER' }
    footer = body['components'].find { |component| component['type'] == 'FOOTER' }
    header == {
      'type' => 'HEADER',
      'format' => 'IMAGE',
      'example' => { 'header_handle' => ['4::header_handle'] }
    } && footer == {
      'type' => 'FOOTER',
      'text' => 'JusMonitorIA — O Futuro da Inteligência Jurídica®'
    } && body['allow_category_change'] == false
  end
end
