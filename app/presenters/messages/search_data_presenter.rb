class Messages::SearchDataPresenter < SimpleDelegator
  def search_data
    {
      # Searchable content
      content: content,
      processed_message_content: processed_message_content,
      attachments: search_attachments_data,
      content_attributes: search_content_attributes_data,
      # Message filters
      account_id: account_id,
      inbox_id: inbox_id,
      conversation_id: conversation_id,
      message_type: message_type,
      private: private,
      created_at: created_at,
      source_id: source_id,
      # related data
      conversation: search_conversation_data,
      inbox: search_inbox_data,
      sender_id: sender_id,
      sender_type: sender_type,
      sender: search_sender_data
    }.merge(search_additional_data)
  end

  private

  def flatten_custom_attributes(attrs)
    return [] if attrs.blank?

    attrs.map do |key, value|
      {
        key: key.to_s,
        value: value.to_s,

        value_type: value.class.name.downcase
      }
    end
  end

  def search_attachments_data
    attachments.filter_map do |a|
      { transcribed_text: a.meta&.dig('transcribed_text') }
    end.presence
  end

  def search_content_attributes_data
    {
      email: {
        subject: content_attributes.dig(:email, :subject) || content_attributes.dig('email', 'subject')
      }.compact
    }.compact
  end

  def search_conversation_data
    {
      id: conversation.id,
      display_id: conversation.display_id,
      status: conversation.status,
      assignee_id: conversation.assignee_id,
      team_id: conversation.team_id,
      contact_id: conversation.contact_id,
      custom_attributes: flatten_custom_attributes(conversation.custom_attributes),
      browser: conversation.additional_attributes&.dig('browser'),
      referer: conversation.additional_attributes&.dig('referer'),
      initiated_at: conversation.additional_attributes&.dig('initiated_at')
    }
  end

  def search_inbox_data
    {
      id: inbox.id,
      name: inbox.name,
      channel_type: inbox.channel_type
    }
  end

  def search_sender_data
    return nil unless sender

    {
      id: sender.id,
      type: sender.class.name,
      name: sender.try(:name),
      email: sender.try(:email),
      phone_number: sender.try(:phone_number),
      custom_attributes: sender.respond_to?(:custom_attributes) ? flatten_custom_attributes(sender.custom_attributes) : []
    }
  end

  def search_additional_data
    {
      campaign_id: additional_attributes&.dig('campaign_id'),
      automation_rule_id: content_attributes&.dig('automation_rule_id')
    }
  end
end

Messages::SearchDataPresenter.prepend_mod_with('Messages::SearchDataPresenter')
