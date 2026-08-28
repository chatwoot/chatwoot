# TODO: Wrap the schema lib under ai-agents
# So we can extend it as Agents::Schema
class Captain::ResponseSchema < RubyLLM::Schema
  string :reasoning, description: "Agent's thought process"
  array :response_parts,
        description: 'Ordered parts of the message to send to the user. Keep all customer-visible text within each part text field.',
        min_items: 1 do
    object do
      string :text, description: 'Customer-visible response text without citation markers or source URLs.', min_length: 1
      array :citation_indexes,
            description: 'Numeric citation indexes from FAQ results that support this text. Use an empty array when none apply.' do
        integer minimum: 1
      end
    end
  end
end
