# CUSTOMIZAÇÃO_SYNAPSEOS
# Parser de mensagens recebidas via Hyperflow.
# Hyperflow normalmente espelha o formato da Cloud API. Quando confirmarmos
# o contrato real, a maior parte dessa implementação pode virar uma subclasse
# direta de IncomingMessageWhatsappCloudService.
class Whatsapp::IncomingMessageHyperflowService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )
    inbox.channel.authorization_error! if url_response.unauthorized?
    Down.download(url_response.parsed_response['url'], headers: inbox.channel.api_headers) if url_response.success?
  end
end
