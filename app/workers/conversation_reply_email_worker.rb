# TODO: lets move this to active job, since thats what we use over all
class ConversationReplyEmailWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers

  def perform(conversation_id, queued_time)
    @conversation = Conversation.find(conversation_id)

    # send the email
    if @conversation.messages.incoming&.last&.content_type == 'incoming_email' || email_inbox?
      ConversationReplyMailer.reply_without_summary(@conversation, queued_time).deliver_later
    else
      ConversationReplyMailer.reply_with_summary(@conversation, queued_time).deliver_later
    end

    # delete the redis set from the first new message on the conversation
    Redis::Alfred.delete(conversation_mail_key)
  end

  private

  def email_inbox?
    @conversation.inbox&.inbox_type == 'Email'
  end

  def conversation_mail_key
    format(::Redis::Alfred::CONVERSATION_MAILER_KEY, conversation_id: @conversation.id)
  end
end
