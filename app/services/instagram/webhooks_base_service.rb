class Instagram::WebhooksBaseService
  attr_reader :channel

  def initialize(channel)
    @channel = channel
  end

  private

  def inbox_channel(_instagram_id)
    @inbox = ::Inbox.find_by(channel: @channel)
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
    instagram_attributes = {
      'social_profiles': { 'instagram': user['username'] },
      'social_instagram_user_name': user['username']
    }

    instagram_attributes['social_instagram_follower_count'] = user['follower_count'] if user['follower_count']
    instagram_attributes['social_instagram_is_user_follow_business'] = user['is_user_follow_business'] if user['is_user_follow_business']
    instagram_attributes['social_instagram_is_business_follow_user'] = user['is_business_follow_user'] if user['is_business_follow_user']

    @contact.update!(additional_attributes: @contact.additional_attributes.merge(instagram_attributes))
  end
end
