module MessageFilterHelpers
  extend ActiveSupport::Concern

  def reportable?
    incoming? || outgoing?
  end

  def webhook_sendable?
    incoming? || outgoing?
  end

  def conversation_transcriptable?
    incoming? || outgoing?
  end

  def email_reply_summarizable?
    incoming? || outgoing? || input_csat?
  end
end
