module Whatsapp::JusmonitoriaCobrancaTemplateDefinition
  PREFIX = 'cobranca_parcela_v'.freeze
  NAME_PATTERN = /\Acobranca_parcela_v\d+\z/
  NAME = "#{PREFIX}1".freeze
  CATEGORY = 'UTILITY'.freeze
  LANGUAGE = 'pt_BR'.freeze
  PARAMETER_FORMAT = 'NAMED'.freeze
  HEADER_IMAGE_URL = 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png'.freeze
  # Mirror the Meta-approved alert footer 1:1 so this template is approved as UTILITY too.
  FOOTER_TEXT = Whatsapp::JusmonitoriaAlertTemplateDefinition::FOOTER_TEXT
  BODY = <<~BODY.strip.freeze
    Olá {{nome}}! 👋

    Passando para lembrar sobre o(s) seguinte(s) pagamento(s) referente(s) aos seus serviços jurídicos:

    {{lista_parcelas}}

    Valor total em aberto: {{valor_total}}

    Caso já tenha efetuado o pagamento, por favor desconsidere esta mensagem. Em caso de dúvida, é só responder por aqui. Obrigado!
  BODY
  DEFINITIONS = {
    NAME => {
      body_text: BODY,
      category: CATEGORY,
      parameter_format: PARAMETER_FORMAT,
      header_format: 'IMAGE',
      header_media_url: HEADER_IMAGE_URL,
      footer_text: FOOTER_TEXT,
      allow_category_change: false
    }
  }.freeze
end
