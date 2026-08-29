class Whatsapp::IdentityPresenter
  include RegexHelper

  def initialize(contact_inbox)
    @contact_inbox = contact_inbox
  end

  def identity
    return if @contact_inbox.blank?

    provider = provider_for(@contact_inbox.inbox.channel)
    type = type_for(@contact_inbox.source_id)
    return if provider.blank? || type.blank?

    {
      type: type,
      value: @contact_inbox.source_id,
      provider: provider,
      inbox_id: @contact_inbox.inbox_id
    }
  end

  def username
    return if identity.blank?

    @contact_inbox.contact.additional_attributes['social_whatsapp_user_name'].presence
  end

  private

  def provider_for(channel)
    return 'whatsapp_cloud' if channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
    return 'twilio' if channel.is_a?(Channel::TwilioSms) && channel.whatsapp?
  end

  def type_for(source_id)
    identifier = source_id.to_s.delete_prefix('whatsapp:')
    return 'phone_number' if identifier.match?(/\A\+?\d{1,15}\z/)
    return 'parent_bsuid' if identifier.match?(/\A[A-Z]{2}\.ENT\./)
    return 'bsuid' if identifier.match?(WHATSAPP_BSUID_REGEX)
  end
end
