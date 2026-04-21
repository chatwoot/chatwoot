# CUSTOMIZAÇÃO_SYNAPSEOS
# Parser de mensagens recebidas via Avisa API.
# APIs estilo Baileys geralmente enviam payloads mais planos (um objeto por
# mensagem). TODO_AVISA: confirmar estrutura contra a documentação atual
# da Avisa antes de ativar em produção.
class Whatsapp::IncomingMessageAvisaService < Whatsapp::IncomingMessageBaseService
  private

  # Avisa publica algo próximo de:
  # {
  #   "event": "message.received",
  #   "phone": "5511999999999",
  #   "message": { "id": "...", "text": "oi", "type": "text", ... }
  # }
  def processed_params
    @processed_params ||= normalize_payload(params.to_unsafe_hash)
  end

  def normalize_payload(raw)
    # Reenvelopa pro formato compatível com IncomingMessageBaseService,
    # espelhando o contrato da Cloud API usado pelas superclasses.
    {
      'messages' => [raw['message']].compact,
      'contacts' => raw['contact'] ? [raw['contact']] : [],
      'metadata' => { 'phone_number_id' => raw['phone'] }
    }
  end

  def download_attachment_file(attachment_payload)
    Down.download(attachment_payload[:url])
  end
end
