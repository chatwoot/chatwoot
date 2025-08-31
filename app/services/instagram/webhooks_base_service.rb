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

    if @contact
      # Update existing contact with identifier if missing
      update_contact_identifier(user) if @contact.identifier.blank? && user['username'].present?
      update_instagram_profile_data(user)
      return
    end

    # Create new contact with identifier
    identifier = (user['username'].presence || "ig_user_#{user['id']}")
    @contact_inbox = @inbox.channel.create_contact_inbox_with_identifier(
      user['id'], user['name'], identifier
    )

    @contact = @contact_inbox.contact
    update_instagram_profile_data(user)
    Avatar::AvatarFromUrlJob.perform_later(@contact, user['profile_pic']) if user['profile_pic']
  end

  def update_instagram_profile_data(user)
    return unless user['username']

    instagram_attributes = build_instagram_attributes(user)
    @contact.update!(additional_attributes: @contact.additional_attributes.merge(instagram_attributes))
  end

  def update_contact_identifier(user)
    return unless user['username'].present?

    @contact.update!(identifier: user['username'])
    Rails.logger.info "[Instagram] Updated existing contact #{@contact.id} with identifier: #{user['username']}"
  rescue ActiveRecord::RecordInvalid => e
    # Handle case where username might already be taken by another contact
    fallback_identifier = "ig_user_#{user['id']}"
    @contact.update!(identifier: fallback_identifier)
    Rails.logger.info "[Instagram] Updated existing contact #{@contact.id} with fallback identifier: #{fallback_identifier} (username conflict: #{e.message})"
  end

  def build_instagram_attributes(user)
    attributes = {
      # TODO: Remove this once we show the social_instagram_user_name in the UI instead of the username
      'social_profiles': { 'instagram': user['username'] },
      'social_instagram_user_name': user['username']
    }

    # Add optional attributes if present
    optional_fields = %w[
      follower_count
      is_user_follow_business
      is_business_follow_user
      is_verified_user
    ]

    optional_fields.each do |field|
      next if user[field].nil?

      attributes["social_instagram_#{field}"] = user[field]
    end

    attributes
  end
end
