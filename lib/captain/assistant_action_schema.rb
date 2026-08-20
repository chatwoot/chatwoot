class Captain::AssistantActionSchema < RubyLLM::Schema
  ACTIONS = %w[continue handoff].freeze
  REASONS = %w[
    general_product_question
    missing_docs_bounded_answer
    clarifying_question_needed
    collect_required_identifier
    external_contact_or_lead_routing
    out_of_scope_bounded_answer
    explicit_human_request
    human_offer_accepted
    account_or_transaction_verification
    operational_issue_needs_inspection
    repeated_frustration_or_loop
    custom_instruction_transfer
  ].freeze

  string :action, enum: ACTIONS, description: 'Whether to keep the conversation with the assistant or transfer it to a human agent'
  string :action_reason, enum: REASONS, description: 'The reason for the selected routing action'
end
