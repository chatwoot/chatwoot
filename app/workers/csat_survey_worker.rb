class CsatSurveyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers, retry: 3

  def perform(conversation_id)
    conversation = Conversation.find(conversation_id)

    return unless conversation.present?
    return unless conversation.inbox.csat_survey_enabled?
    return unless conversation.messages.csat.present?

    # send the email
    ConversationReplyMailer.with(account: conversation.account).csat_survey(conversation).deliver_later
  end
end
