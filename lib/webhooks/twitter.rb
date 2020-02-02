# frozen_string_literal: true

class Webhooks::Twitter
  SUPPORTED_EVENTS = [:direct_message_events].freeze

  attr_accessor :params, :account

  def initialize(params)
    @params = params
  end

  def consume
    send(event_name) if event_name
  end

  private

  def event_name
    @event_name ||= SUPPORTED_EVENTS.find { |key| @params.key?(key.to_s) }
  end

  def users
    @params[:users]
  end

  def profile_id
    @params[:for_user_id]
  end

  def set_inbox
    twitter_profile = Channel::TwitterProfile.find_by(profile_id: @params[:for_user_id])
    @inbox = Inbox.find_by!(channel: twitter_profile)
  end

  def ensure_contacts
    @params[:users].each do |key, user|
      next if key == profile_id

      find_or_create_contact(user)
    end
  end

  def find_or_create_contact(user)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: user['id']).first
    @contact = @contact_inbox.contact if @contact_inbox
    return if @contact

    @contact_inbox = @inbox.channel.create_contact_inbox(user['id'], user['name'])
    @contact = @contact_inbox.contact
    avatar_resource = LocalResource.new(user['profile_image_url'])
    @contact.avatar.attach(io: avatar_resource.file, filename: avatar_resource.tmp_filename, content_type: avatar_resource.encoding)
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def outgoing_message?
    @params['direct_message_events'].first['message_create']['sender_id'] == @inbox.channel.profile_id
  end

  def direct_message_events
    set_inbox
    ensure_contacts
    set_conversation
    @conversation.messages.create(
      content: @params['direct_message_events'].first['message_create']['message_data']['text'],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: outgoing_message? ? :outgoing : :incoming
    )
  end
end
