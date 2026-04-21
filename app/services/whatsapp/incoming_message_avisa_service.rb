# CUSTOMIZAÇÃO_SYNAPSEOS
# Parser de mensagens recebidas que o N8N encaminha pro Chatwoot.
# O flow N8N normaliza o payload whatsmeow/Baileys da Avisa (vem via
# application/x-www-form-urlencoded com campo jsonData stringificado)
# para o envelope Meta Cloud API que o Chatwoot já parseia nativamente.
class Whatsapp::IncomingMessageAvisaService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    url = attachment_payload[:url] || attachment_payload['url']
    return if url.blank?

    Down.download(url)
  rescue StandardError => e
    Rails.logger.warn("[AVISA] falha ao baixar mídia #{url}: #{e.message}")
    nil
  end
end
