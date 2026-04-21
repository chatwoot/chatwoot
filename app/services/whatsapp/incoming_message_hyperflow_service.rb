# CUSTOMIZAÇÃO_SYNAPSEOS
# Parser de mensagens recebidas que o N8N encaminha pro Chatwoot.
#
# A recomendação é que o flow N8N monte o payload no mesmo shape da
# WhatsApp Cloud API (entry[].changes[].value.{messages,contacts}),
# porque o Chatwoot já tem parsers maduros pra esse formato. Quando
# Hyperflow enviar um corpo levemente diferente, o nó N8N ajusta antes
# de chamar `/webhooks/hyperflow/:phone_number`.
class Whatsapp::IncomingMessageHyperflowService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  # Hyperflow envia URLs de mídia públicas via N8N (sem token); basta baixar.
  def download_attachment_file(attachment_payload)
    url = attachment_payload[:url] || attachment_payload['url']
    return if url.blank?

    Down.download(url)
  rescue StandardError => e
    Rails.logger.warn("[HYPERFLOW] falha ao baixar mídia #{url}: #{e.message}")
    nil
  end
end
