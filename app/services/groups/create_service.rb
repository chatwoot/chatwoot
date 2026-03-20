class Groups::CreateService
  pattr_initialize [:inbox!, :subject!, :participants!]

  def perform
    group_data = channel.create_group(subject, format_participants)
    group_jid = group_data&.dig(:id)
    raise Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Group JID missing from response' if group_jid.blank?

    { group_jid: group_jid }
  end

  private

  def channel
    inbox.channel
  end

  def format_participants
    participants.map { |phone| "#{phone.delete('+')}@s.whatsapp.net" }
  end
end
