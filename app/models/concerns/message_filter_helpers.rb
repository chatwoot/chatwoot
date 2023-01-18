module MessageFilterHelpers
  extend ActiveSupport::Concern

  def reportable?
    incoming? || outgoing?
  end

  def webhook_sendable?
    incoming? || outgoing?
  end

  def notifiable?
    incoming? || outgoing?
  end

  def conversation_transcriptable?
    incoming? || outgoing?
  end

  def email_reply_summarizable?
    incoming? || outgoing? || input_csat?
  end

  def instagram_story_mention?
    inbox.instagram? && try(:content_attributes)[:image_type] == 'story_mention'
  end
end
