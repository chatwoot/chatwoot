class Integrations::Slack::UpdateSlackMessageService
  include RegexHelper

  SUPPORTED_CONTENT_TYPES = %w[input_select form input_csat input_email].freeze

  pattr_initialize [:message!, :hook!]

  def perform
    return unless updateable_message?

    slack_client.chat_update(
      channel: hook.reference_id,
      ts: slack_message_ts,
      text: updated_message_content
    )
  rescue Slack::Web::Api::Errors::MessageNotFound => e
    # Original Slack message no longer exists (e.g. channel was reconfigured), skip gracefully.
    Rails.logger.error "[Slack] chat_update failed (account=#{message.account_id}, hook=#{hook.id}): #{e.message}"
  rescue Slack::Web::Api::Errors::IsArchived, Slack::Web::Api::Errors::AccountInactive, Slack::Web::Api::Errors::MissingScope,
         Slack::Web::Api::Errors::InvalidAuth,
         Slack::Web::Api::Errors::ChannelNotFound, Slack::Web::Api::Errors::NotInChannel => e
    Rails.logger.error "[Slack] chat_update failed (account=#{message.account_id}, hook=#{hook.id}): #{e.message}"
    hook.prompt_reauthorization!
    hook.disable
  end

  private

  def updateable_message?
    hook&.reference_id.present? &&
      slack_message_ts.present? &&
      message.content_type.in?(SUPPORTED_CONTENT_TYPES) &&
      (message.submitted_values.present? || message.submitted_email.present?)
  end

  def slack_message_ts
    source_id = message.external_source_id_slack.to_s
    return unless source_id.start_with?('cw-origin-')

    source_id.delete_prefix('cw-origin-').presence
  end

  def updated_message_content
    question = sanitized_content(message_text).presence
    response = formatted_response

    return question.to_s if response.blank?

    [question, response].compact.join("\n\n")
  end

  def formatted_response
    case message.content_type
    when 'input_select'
      format_input_select_response
    when 'form'
      format_form_response
    when 'input_csat'
      format_csat_response
    when 'input_email'
      format_email_response
    end
  end

  def format_input_select_response
    item = Array(message.submitted_values).first
    return if item.blank?

    value = item['title'] || item[:title] || item['value'] || item[:value]
    value = sanitized_content(value)
    return if value.blank?

    "*Response:* #{value}"
  end

  def format_email_response
    email = sanitized_content(message.submitted_email)
    return if email.blank?

    "*Email:* #{email}"
  end

  def format_form_response
    submitted_values = Array(message.submitted_values)
    return if submitted_values.blank?

    items_by_name = Array(message.items).index_by { |i| flex_value(i, 'name') }

    lines = submitted_values.filter_map do |sv|
      format_form_line(sv, items_by_name)
    end

    return if lines.blank?

    "*Responses:*\n#{lines.join("\n")}"
  end

  def format_csat_response
    csat_response = flex_value(message.submitted_values, 'csat_survey_response', 'csatSurveyResponse')
    return if csat_response.blank?

    rating = flex_value(csat_response, 'rating')
    feedback = flex_value(csat_response, 'feedback_message', 'feedbackMessage')

    lines = []
    lines << "• Rating: #{rating}" if rating.present?
    lines << "• Feedback: #{sanitized_content(feedback)}" if feedback.present?

    return if lines.blank?

    "*CSAT:*\n#{lines.join("\n")}"
  end

  def format_form_line(submitted_value, items_by_name)
    name = flex_value(submitted_value, 'name')
    value = sanitized_content(flex_value(submitted_value, 'value'))
    return if value.blank?

    label = sanitized_content(flex_value(items_by_name[name], 'label') || name)
    return if label.blank?

    "• #{label}: #{value}"
  end

  def flex_value(hash, *keys)
    return if hash.blank?

    keys.each do |key|
      value = hash[key.to_sym] || hash[key.to_s]
      return value if value.present?
    end
    nil
  end

  def message_text
    content = message.processed_message_content || message.content

    if content.present?
      content.to_s.gsub(MENTION_REGEX, '\1')
    else
      content
    end
  end

  def sanitized_content(text)
    ActionView::Base.full_sanitizer.sanitize(text.to_s).strip
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end
end
