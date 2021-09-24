class Webhooks::InstagramEventsJob < ApplicationJob
  queue_as :default

  include HTTParty

  base_uri 'https://graph.facebook.com/v11.0/me'

  # @return [Array] We will support further events like reaction or seen in future
  SUPPORTED_EVENTS = [:message].freeze

  # @see https://developers.facebook.com/docs/messenger-platform/instagram/features/webhook
  def perform(entries)
    @entries = entries

    if @entries[0].key?(:changes)
      Rails.logger.info('Probably Test data.')
      # grab the test entry for the review app
      create_test_text
      return
    end

    @entries.each do |entry|
      entry[:messaging].each do |messaging|
        send(@event_name, messaging) if event_name(messaging)
      end
    end
  end

  private

  def event_name(messaging)
    @event_name ||= SUPPORTED_EVENTS.find { |key| messaging.key?(key) }
  end

  def message(messaging)
    ::Instagram::MessageText.new(messaging).perform
  end

  def create_test_text
    messenger_channel = Channel::FacebookPage.last
    @inbox = ::Inbox.find_by!(channel: messenger_channel)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: 'sender_username').first
    unless @contact_inbox
      @contact_inbox ||= @inbox.channel.create_contact_inbox(
        'sender_username', 'sender_username'
      )
    end
    @contact = @contact_inbox.contact

    @conversation ||= Conversation.find_by(conversation_params) || build_conversation(conversation_params)

    @message = @conversation.messages.create!(message_params)
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      additional_attributes: {
        type: 'instagram_direct_message'
      }
    }
  end

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: 'incoming',
      source_id: 'facebook_test_webhooks',
      content: 'This is a test message from facebook.',
      sender: @contact
    }
  end

  def build_conversation(conversation_params)
    Conversation.create!(
      conversation_params.merge(
        contact_inbox_id: @contact_inbox.id
      )
    )
  end
end
