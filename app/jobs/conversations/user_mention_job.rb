class Conversations::UserMentionJob < ApplicationJob
  queue_as :default

  def perform(mentioned_user_ids, conversation_id, account_id)
    mentioned_user_ids.each do |mentioned_user_id|
      mention = Mention.find_by(
        user_id: mentioned_user_id,
        conversation_id: conversation_id,
        account_id: account_id
      )

      if mention.nil?
        Mention.create(
          user_id: mentioned_user_id,
          conversation_id: conversation_id,
          mentioned_at: Time.zone.now,
          account_id: account_id
        )
      else
        mention.update(mentioned_at: Time.zone.now)
      end
    end
  end
end
