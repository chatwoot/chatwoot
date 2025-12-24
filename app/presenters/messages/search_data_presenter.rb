class Messages::SearchDataPresenter < SimpleDelegator
  def search_data
    {
      **searchable_content,
      **message_attributes,
      additional_attributes: additional_attributes_data,
      conversation: conversation_data
    }
  end

  private

  def searchable_content
    {
      content: content,
      attachments: attachment_data,
      content_attributes: content_attributes_data
    }
  end

  def message_attributes
    {
      account_id: account_id,
      inbox_id: inbox_id,
      conversation_id: conversation_id,
      message_type: message_type,
      private: private,
      created_at: created_at,
      source_id: source_id,
      sender_id: sender_id,
      sender_type: sender_type
    }
  end

  def attachment_data
    attachments.filter_map do |a|
      { transcribed_text: a.meta&.dig('transcribed_text') }
    end.presence
  end

  def content_attributes_data
    email_subject = content_attributes.dig(:email, :subject)
    return {} if email_subject.blank?

    { email: { subject: email_subject } }
  end

  def conversation_data
    { id: conversation.display_id }
  end

  def additional_attributes_data
    {
      campaign_id: additional_attributes&.dig('campaign_id'),
      automation_rule_id: content_attributes&.dig('automation_rule_id')
    }
  end
end
