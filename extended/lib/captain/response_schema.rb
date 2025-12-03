# ============================================================================
# MARK: TO BE DELETED
# This file will be replaced by new provider abstraction implementation.
# ============================================================================

require 'ruby_llm'

# TODO: Wrap the schema lib under ai-agents
# So we can extend it as Agents::Schema
class Captain::ResponseSchema < RubyLLM::Schema
  string :response, description: 'The message to send to the user'
  string :reasoning, description: "Agent's thought process"
end
