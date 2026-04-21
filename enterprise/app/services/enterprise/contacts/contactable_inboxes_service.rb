module Enterprise::Contacts::ContactableInboxesService
  private

  # Extend base selection to include Voice inboxes
  def get_contactable_inbox(inbox)
    return voice_contactable_inbox(inbox) if inbox.channel_type == 'Channel::Voice'

    super
  end

  def voice_contactable_inbox(inbox)
    return if @contact.phone_number.blank?

    { source_id: @contact.phone_number, inbox: inbox }
  end
end
