class Captain::AgentReplySchema < Schematist::Schema
  boolean :reply_needed, description: 'False when the conversation needs no reply from the agent right now'
  string :reply, description: 'The message to send to the customer, exactly as it should be sent. Empty when no reply is needed'
  string :note_for_agent, description: 'A short note for the agent only, never shown to the customer. Says why no reply is needed, or what to check'
end
