class Inbox::EventDataPresenter < SimpleDelegator
  def push_data
    {
      # Conversation thread config
      allow_messages_after_resolved: allow_messages_after_resolved,
      lock_to_single_conversation: lock_to_single_conversation,

      # Auto Assignment config
      auto_assignment_config: auto_assignment_config,
      enable_auto_assignment: enable_auto_assignment,

      # Feature flag for message events
      enable_email_collect: enable_email_collect,
      greeting_enabled: greeting_enabled,
      greeting_message: greeting_message,
      csat_survey_enabled: csat_survey_enabled,

      # Outbound email sender config
      business_name: business_name,
      sender_name_type: sender_name_type,

      # Business hour config
      timezone: timezone,
      out_of_office_message: out_of_office_message,
      working_hours_enabled: working_hours_enabled,
      working_hours: working_hours,

      created_at: created_at,
      updated_at: updated_at,

      # Associated channel attributes
      channel: channel
    }
  end
end
