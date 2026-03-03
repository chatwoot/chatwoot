class Influencers::ConversationService
  class ChannelUnavailableError < StandardError; end

  def initialize(profile:, inbox:, user:)
    @profile = profile
    @contact = profile.contact
    @inbox = inbox
    @user = user
  end

  def find_or_create_conversation
    validate_channel!

    existing = @contact.conversations
                       .where(inbox: @inbox, status: %i[open pending])
                       .order(created_at: :desc)
                       .first
    return existing if existing

    contact_inbox = find_or_create_contact_inbox
    Conversation.create!(
      account: @profile.account,
      inbox: @inbox,
      contact: @contact,
      contact_inbox: contact_inbox,
      assignee: @user,
      status: :open
    )
  end

  # Returns hash of { inbox_id => reason } for unavailable inboxes
  def self.availability(profile)
    contact = profile.contact
    profile.account.inboxes.each_with_object({}) do |inbox, result|
      reason = case inbox.channel_type
               when 'Channel::Email'
                 'No email address on contact' if contact.email.blank?
               when 'Channel::Instagram'
                 instagram_unavailable_reason(inbox.channel)
               end
      result[inbox.id] = { available: reason.nil?, reason: reason, name: inbox.name, channel_type: inbox.channel_type }
    end
  end

  def self.instagram_unavailable_reason(channel)
    return 'Instagram channel not configured' if channel.blank?
    return 'Instagram requires reconnection' if channel.reauthorization_required?
    return 'Instagram token expired' if channel.access_token.blank?

    nil
  end

  private

  def validate_channel!
    source = resolve_source_id
    return if source.present?

    message = case @inbox.channel_type
              when 'Channel::Email' then 'Contact has no email address. Add an email to send messages.'
              when 'Channel::Instagram' then 'Influencer has no Instagram username.'
              else 'Channel source not available.'
              end
    raise ChannelUnavailableError, message
  end

  def find_or_create_contact_inbox
    ContactInbox.find_by(contact: @contact, inbox: @inbox) ||
      ContactInbox.create!(contact: @contact, inbox: @inbox, source_id: resolve_source_id)
  end

  def resolve_source_id
    case @inbox.channel_type
    when 'Channel::Email'
      @contact.email.presence
    when 'Channel::Instagram'
      @profile.username
    else
      SecureRandom.uuid
    end
  end
end
