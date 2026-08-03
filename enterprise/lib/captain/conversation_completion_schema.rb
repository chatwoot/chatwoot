class Captain::ConversationCompletionSchema < RubyLLM::Schema
  ACTIONS = %w[resolve follow_up handoff].freeze

  string :action, enum: ACTIONS, description: 'The safest next action for the inactive conversation'
  string :reason, description: 'Brief explanation for the selected action'
  string :follow_up_message, description: 'Context-specific customer follow-up, or an empty string unless the action is follow_up'
end
