class MessageTemplates::Template::CsatSurvey
  pattr_initialize [:conversation!]

  def perform
    return unless should_send_csat_survey?

    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_survey_message_params)
    end
  end

  private

  delegate :contact, :account, :inbox, to: :conversation
  delegate :csat_config, to: :inbox

  def should_send_csat_survey?
    return true unless survey_rules_configured?

    labels = conversation.label_list

    return true if rule_values.empty?

    case rule_operator
    when 'contains'
      rule_values.any? { |label| labels.include?(label) }
    when 'does_not_contain'
      rule_values.none? { |label| labels.include?(label) }
    else
      true
    end
  end

  def survey_rules_configured?
    return false if csat_config.blank?
    return false if csat_config['survey_rules'].blank?
    return false if rule_values.empty?

    true
  end

  def rule_operator
    csat_config.dig('survey_rules', 'operator') || 'contains'
  end

  def rule_values
    csat_config.dig('survey_rules', 'values') || []
  end

  def message_content
    return I18n.t('conversations.templates.csat_input_message_body') if csat_config.blank? || csat_config['message'].blank?

    csat_config['message']
  end

  def csat_survey_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_csat,
      content: message_content,
      content_attributes: content_attributes
    }
  end

  def csat_config
    inbox.csat_config || {}
  end

  def content_attributes
    {
      display_type: csat_config['display_type'] || 'emoji'
    }
  end
end
