class Captain::AssistantMigration::InstructionClassifierSchema < RubyLLM::Schema
  SECTION_ITEM_DESCRIPTION = 'A single migrated instruction item. Keep value concise and preserve meaning.'.freeze

  def self.instruction_items(field_name, description:, max_items: 20)
    array field_name, description: description, max_items: max_items do
      object do
        string :value, description: 'Migrated instruction text.', max_length: 500
        string :confidence, description: 'One of: high, medium, low.', max_length: 20
        string :review_reason, description: 'Why this item needs review. Empty string when confidence is high.', max_length: 300
      end
    end
  end

  instruction_items :business_product_context,
                    description: 'Who the assistant is, what business/product it supports, and what context it should know.',
                    max_items: 10

  instruction_items :response_guidelines,
                    description: 'Tone, language, answer length, formatting, and clarification behavior.',
                    max_items: 20

  instruction_items :guardrails,
                    description: 'Refusal rules, escalation boundaries, source boundaries, safety limits, and things the assistant must not do.',
                    max_items: 20

  instruction_items :scenarios_procedures,
                    description: 'Only clear multi-step workflows, routing logic, qualification flows, handoff flows, or tool-use procedures.',
                    max_items: 15

  object :conversation_messages, description: 'Exact customer-facing message copy found in instructions and not already present in config.' do
    string :welcome_message, description: 'Exact welcome message copy from instructions only when config welcome_message is blank, or empty string.',
                             max_length: 1000
    string :handoff_message,
           description: 'Exact human-handoff message copy from instructions only when config handoff_message is blank, or empty string.',
           max_length: 1000
    string :resolution_message,
           description: 'Exact resolution/closing message copy from instructions only when config resolution_message is blank, or empty string.',
           max_length: 1000
  end

  instruction_items :faq_document_candidates,
                    description: 'Only factual or product-specific knowledge candidates such as pricing, policy, setup, troubleshooting, ' \
                                 'or operational details.',
                    max_items: 25

  instruction_items :needs_review,
                    description: 'Unclear, conflicting, risky, duplicated, or low-confidence content that needs human review.',
                    max_items: 20

  array :classification_notes, description: 'Short notes about important migration decisions or risks.', max_items: 10, of: :string
end
