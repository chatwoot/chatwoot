class Instagram::WebhooksBaseService
  private

  def inbox_channel(instagram_id)
    messenger_channel = Channel::FacebookPage.where(instagram_id: instagram_id)
    @inbox = ::Inbox.find_by(channel: messenger_channel)
  end

  def find_or_create_contact(user)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: user['id']).first
    @contact = @contact_inbox.contact if @contact_inbox

    update_instagram_profile_link(user) && return if @contact

    @contact_inbox = @inbox.channel.create_contact_inbox(
      user['id'], user['name']
    )

    @contact = @contact_inbox.contact
    update_instagram_profile_link(user)
    Avatar::AvatarFromUrlJob.perform_later(@contact, user['profile_pic']) if user['profile_pic']
  end

  def update_instagram_profile_link(user)
    return unless user['username']

    # TODO: Remove this once we show the social_instagram_user_name in the UI instead of the username
    @contact.additional_attributes = @contact.additional_attributes.merge({ 'social_profiles': { 'instagram': user['username'] } })
    @contact.additional_attributes = @contact.additional_attributes.merge({ 'social_instagram_user_name': user['username'] })
    @contact.save
  end
end
