class Captain::AssistantFalsePromiseSchema < RubyLLM::Schema
  DECISIONS = %w[safe future_work_promise].freeze
  REASONS = %w[
    safe_response
    asks_user_to_check_or_provide_info
    external_support_direction
    unaccepted_handoff_offer
    future_check_or_investigation
    future_notification_or_update
    future_callback_or_email
    background_escalation_promise
  ].freeze

  string :decision, enum: DECISIONS, description: 'Whether the response contains an unsupported promise of future work'
  string :reason, enum: REASONS, description: 'The reason for the selected decision'
end
