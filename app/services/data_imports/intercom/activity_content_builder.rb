class DataImports::Intercom::ActivityContentBuilder
  EVENT_KEYS = {
    'assignment' => :assignment,
    'assign_and_reopen' => :assign_and_reopen,
    'open' => :open,
    'close' => :close,
    'snoozed' => :snoozed,
    'participant_added' => :participant_added,
    'participant_removed' => :participant_removed,
    'conversation_attribute_updated_by_admin' => :conversation_attribute_updated,
    'conversation_attribute_updated_by_user' => :conversation_attribute_updated,
    'conversation_attribute_updated_by_workflow' => :conversation_attribute_updated,
    'ticket_attribute_updated_by_admin' => :ticket_attribute_updated,
    'ticket_state_updated_by_admin' => :ticket_state_updated,
    'custom_action_started' => :custom_action_started,
    'custom_action_finished' => :custom_action_finished,
    'quick_reply' => :quick_reply
  }.freeze

  def initialize(part)
    @part = part.to_h
  end

  def perform
    append_body(translated_content)
  end

  private

  def translated_content
    key = EVENT_KEYS.fetch(event_type, :generic)
    key = "#{key}_with_target" if target_aware_event?(key) && target_name.present?

    I18n.t(
      "data_imports.intercom.activities.#{key}",
      actor: actor_name,
      target: target_name,
      event: event_type.tr('_', ' ')
    )
  end

  def event_type
    @part['part_type'].to_s
  end

  def actor_name
    author = @part['author'].to_h
    return author['name'] if author['name'].present?

    case author['type']
    when 'user', 'contact', 'lead'
      'Contact'
    when 'bot'
      'Intercom automation'
    else
      automation_event? ? 'Intercom automation' : 'Intercom teammate'
    end
  end

  def target_name
    assigned_to = @part['assigned_to'].to_h
    event_details = @part['event_details'].to_h
    participant = event_details['participant'].to_h

    assigned_to['name'].presence || participant['name'].presence || event_details['participant_name'].presence || event_details['name'].presence
  end

  def target_aware_event?(key)
    %i[assignment assign_and_reopen participant_added participant_removed].include?(key)
  end

  def automation_event?
    event_type.include?('workflow') || event_type.start_with?('custom_action')
  end

  def append_body(content)
    fragment = Nokogiri::HTML5.fragment(@part['body'].to_s)
    fragment.css('script, style').remove
    body = fragment.text.squish
    return content if body.blank? || content.downcase.include?(body.downcase)

    "#{content}: #{body}"
  end
end
