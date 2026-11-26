# TODO: Wrap the schema lib under ai-agents
# So we can extend it as Agents::Schema
class Captain::ResponseSchema < Schematist::Schema
  # Schematist keeps properties per class, so a subclass declares its fields again through this method.
  def self.define_response_fields(handoff:)
    string :reasoning, description: 'Brief basis for the answer'
    if handoff
      boolean :handoff,
              description: 'True only when the customer asked for a person or accepted an offer to be connected with one, and this reply ' \
                           'tells them that a person is taking over the conversation now. False for every other reply, including replies ' \
                           'that offer a person or suggest another way to reach the team.'
    end
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

  define_response_fields(handoff: false)
end
