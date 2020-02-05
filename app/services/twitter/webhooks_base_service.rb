class Twitter::WebhooksBaseService
  private

  def profile_id
    payload[:for_user_id]
  end

  def set_inbox
    twitter_profile = ::Channel::TwitterProfile.find_by(profile_id: profile_id)
    @inbox = ::Inbox.find_by!(channel: twitter_profile)
  end

  def find_or_create_contact(user)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: user['id']).first
    @contact = @contact_inbox.contact if @contact_inbox
    return if @contact

    @contact_inbox = @inbox.channel.create_contact_inbox(user['id'], user['name'])
    @contact = @contact_inbox.contact
    avatar_resource = LocalResource.new(user['profile_image_url'])
    @contact.avatar.attach(
      io: avatar_resource.file,
      filename: avatar_resource.tmp_filename,
      content_type: avatar_resource.encoding
    )
  end
end
