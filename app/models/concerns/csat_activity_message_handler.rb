module CsatActivityMessageHandler
  extend ActiveSupport::Concern

  def create_csat_not_sent_activity_message
    content = I18n.t('conversations.activity.csat.not_sent_due_to_messaging_window')
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end
end
