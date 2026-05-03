module Whatsapp::JusmonitoriaAlertTemplateDefinition
  PREFIX = 'alerta_movimentacao_processual_v'.freeze
  NAME_PATTERN = /\Aalerta_movimentacao_processual_v\d+\z/
  NAME = "#{PREFIX}1".freeze
  V2_NAME = "#{PREFIX}2".freeze
  CATEGORY = 'UTILITY'.freeze
  LANGUAGE = 'pt_BR'.freeze
  PARAMETER_FORMAT = 'NAMED'.freeze
  HEADER_IMAGE_URL = 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png'.freeze
  FOOTER_TEXT = 'JusMonitorIA — O Futuro da Inteligência Jurídica®'.freeze
  BODY = <<~BODY.strip.freeze
    ⚖️ Atualização processual

    O JusMonitorIA identificou novas movimentações nos processos que você acompanha:

    {{lista_processos}}

    📌 Para consultar histórico completo, documentos e possíveis prazos, acesse os links dos processos acima.
  BODY
  DEFINITIONS = {
    NAME => {
      body_text: BODY,
      category: CATEGORY,
      parameter_format: PARAMETER_FORMAT
    },
    V2_NAME => {
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
