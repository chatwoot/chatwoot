class Tiktok::ReadStatusService
  include Tiktok::MessagingHelpers

  pattr_initialize [:channel!, :content!]

  def perform
    return if channel.blank? || content.blank? || outbound_event? || conversation.blank?

    ::Conversations::UpdateMessageStatusJob.perform_later(conversation.id, last_read_timestamp)
  end

  def conversation
    @conversation ||= find_conversation(channel, tt_conversation_id)
  end

  def tt_conversation_id
    content[:conversation_id]
  end

  def last_read_timestamp
    tt = content[:read][:last_read_timestamp]
    Time.zone.at(tt.to_i / 1000).utc
  end

  def business_id
    channel.business_id
  end

  def from_user_id
    content[:from_user][:id]
  end

  def outbound_event?
    business_id.to_s == from_user_id.to_s
  end
end
