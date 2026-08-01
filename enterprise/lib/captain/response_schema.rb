# TODO: Wrap the schema lib under ai-agents
# So we can extend it as Agents::Schema
class Captain::ResponseSchema < RubyLLM::Schema
  string :response, description: 'The message to send to the user'
  string :reasoning, description: "Agent's thought process"

  object :case_state, description: 'Internal structured state for the active customer issue. Never expose this object to the customer.' do
    string :active_issue, description: 'Concise description of the issue currently being handled.', max_length: 300
    string :customer_goal, description: 'The outcome the customer is trying to achieve.', max_length: 300
    string :topic, description: 'The product area or support topic for the active issue.', max_length: 100
    array :known_facts, description: 'Verified case-specific facts supplied by the customer or trusted tools.', max_items: 20, of: :string
    array :missing_information, description: 'Facts still required to choose or complete the next support action.', max_items: 10, of: :string
    array :attempted_steps, description: 'Troubleshooting steps already attempted and their observed results.', max_items: 15, of: :string
    string :pending_action, description: 'The single next action expected from the customer or assistant.', max_length: 300
  end
end
