module MessageFilterHelpers
  extend ActiveSupport::Concern

  def reportable?
    incoming? || outgoing?
  end

  def webhook_sendable?
    return false if imported_from_history?

    incoming? || outgoing? || template?
  end

  def slack_hook_sendable?
    return false if imported_from_history?

    incoming? || outgoing? || template?
  end

  def notifiable?
    return false if imported_from_history?

    (incoming? || outgoing?) && !private?
  end

  def imported_from_history?
    content_attributes&.dig('imported_from_history') == true
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
