class Instagram::WebhooksBaseService
  private

  def inbox_channel(instagram_id)
    messenger_channel = Channel::FacebookPage.where(instagram_id: instagram_id)
    @inbox = ::Inbox.find_by(channel: messenger_channel)
  end

  def find_or_create_contact(user)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: user['id']).first
    @contact = @contact_inbox.contact if @contact_inbox
    return if @contact

    @contact_inbox = @inbox.channel.create_contact_inbox(
      user['id'], user['name']
    )

    update_instagram_profile_link(user)
    @contact = @contact_inbox.contact
    Avatar::AvatarFromUrlJob.perform_later(@contact, user['profile_pic']) if user['profile_pic']
  end

  def update_instagram_profile_link
    return unless user['username']

    @contact.additional_attributes = @contact.additional_attributes.merge({
                                                                            social_profiles: { instagram: user['username'] }
                                                                          })
    @contact.save
  end
end
