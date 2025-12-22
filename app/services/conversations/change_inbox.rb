# frozen_string_literal: true

class Conversations::ChangeInbox
  def self.call(conversation:, inbox_id:)
    new(conversation, inbox_id).call
  end

  def initialize(conversation, inbox_id)
    @conversation = conversation
    @new_inbox = Current.account.inboxes.find(inbox_id)
    @old_inbox = conversation.inbox
  end

  def call
    ActiveRecord::Base.transaction do
      conversation.update!(inbox: new_inbox)
      conversation.contact_inbox.update!(inbox: new_inbox)

      Conversations::SendInboxChangedNotification.call(conversation, old_inbox, new_inbox)
    end

    broadcast_change
    self
  end

  attr_reader :conversation, :new_inbox, :old_inbox

  private

  def broadcast_change
    ActionCable.server.broadcast(
      conversation.contact_inbox.pubsub_token,
      {
        event: 'inbox.changed',
        data: {
          website_token: new_inbox.channel.website_token
        }
      }
    )
  end
end
