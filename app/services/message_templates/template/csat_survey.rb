class MessageTemplates::Template::CsatSurvey
  pattr_initialize [:conversation!]

  def perform
    return unless should_send_csat_survey?

    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_survey_message_params)
    end
  end

  private

  delegate :contact, :account, to: :conversation

  def should_send_csat_survey?
    # Return true if no survey rules are configured
    return true unless survey_rules_configured?

    # Get the conversation labels
    labels = conversation_labels

    # Apply the rule based on the operator
    case rule_operator
    when 'contains'
      # Check if any configured label exists in the conversation's labels
      rule_values.any? { |label| labels.include?(label) }
    when 'does_not_contain'
      # Check that none of the configured labels exist in the conversation's labels
      rule_values.none? { |label| labels.include?(label) }
    else
      true
    end
  end

  def conversation_labels
    # Use cached_label_list if available, otherwise fall back to other methods
    return conversation.cached_label_list.split(', ') if conversation.cached_label_list.present?

    []
  end

  def survey_rules_configured?
    return false if inbox.csat_config.blank?
    return false if inbox.csat_config['survey_rules'].blank?
    return false unless inbox.csat_config['survey_rules']['values'].is_a?(Array)
    return false if inbox.csat_config['survey_rules']['values'].empty?

    true
  end

  def rule_operator
    inbox.csat_config.dig('survey_rules', 'operator') || 'contains'
  end

  def rule_values
    inbox.csat_config.dig('survey_rules', 'values') || []
  end

  def inbox
    @inbox ||= conversation.inbox
  end

  def custom_message
    return I18n.t('conversations.templates.csat_input_message_body') if inbox.csat_config.blank? || inbox.csat_config['message'].blank?

    inbox.csat_config['message']
  end

  def csat_survey_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_csat,
      content: custom_message,
      content_attributes: build_content_attributes
    }
  end

  def build_content_attributes
    attributes = {}

    # Add display_type if present in the configuration
    attributes[:display_type] = inbox.csat_config['display_type'] if inbox.csat_config.present? && inbox.csat_config['display_type'].present?

    attributes
  end
end
