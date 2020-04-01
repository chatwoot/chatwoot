class Twitter::WebhooksBaseService
  private

  def profile_id
    payload[:for_user_id]
  end

  def additional_contact_attributes(user)
    {
      screen_name: user['screen_name'],
      location: user['location'],
      url: user['url'],
      description: user['description'],
      followers_count: user['followers_count'],
      friends_count: user['friends_count']
    }
  end

  def set_inbox
    twitter_profile = ::Channel::TwitterProfile.find_by(profile_id: profile_id)
    @inbox = ::Inbox.find_by!(channel: twitter_profile)
  end

  def find_or_create_contact(user)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: user['id']).first
    @contact = @contact_inbox.contact if @contact_inbox
    return if @contact

    @contact_inbox = @inbox.channel.create_contact_inbox(
      user['id'], user['name'], additional_contact_attributes(user)
    )
    @contact = @contact_inbox.contact
    ContactAvatarJob.perform_later(@contact, user['profile_image_url']) if user['profile_image_url']
  end
end
