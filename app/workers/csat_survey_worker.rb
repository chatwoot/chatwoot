class CsatSurveyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers, retry: 3

  def perform(conversation_id)
    conversation = Conversation.find(conversation_id)

    return if conversation.blank?
    return unless conversation.inbox.csat_survey_enabled?
    return if conversation.messages.csat.blank?

    # send the email
    ConversationReplyMailer.with(account: conversation.account).csat_survey(conversation).deliver_later
  end
end
