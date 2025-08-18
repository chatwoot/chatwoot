module Enterprise::ContactInboxBuilder
  private

  def generate_source_id
    return super unless @inbox.channel_type == 'Channel::Voice'
    phone_source_id
  end

  def phone_source_id
    return super unless @inbox.channel_type == 'Channel::Voice'
    return SecureRandom.uuid unless @contact.phone_number.present?
    @contact.phone_number
  end

  def allowed_channels?
    super || @inbox.channel_type == 'Channel::Voice'
  end
end

