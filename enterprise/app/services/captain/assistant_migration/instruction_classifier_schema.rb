class Captain::AssistantMigration::InstructionClassifierSchema < RubyLLM::Schema
  def self.instruction_items(field_name, description:, max_items: 20)
    array field_name,
          description: "#{description} Return plain standalone sentences without numbering, bullets, or section labels.",
          max_items: max_items,
          of: :string
  end

  array :business_product_context,
        description: 'Single compact root assistant description for the root orchestrator prompt, maximum 200 characters: ' \
                     'preserve the existing assistant description and enrich it only with relevant business/product context from the ' \
                     'custom instructions. Include assistant identity, product scope, high-level mission, and high-level source/routing ' \
                     'priorities only. Do not include workflows, procedures, attribute glossaries, policy details, or long inventories. ' \
                     'Return one plain standalone sentence without numbering, bullets, or section labels.',
        min_items: 1,
        max_items: 1 do
    string max_length: 200
  end

  instruction_items :response_guidelines,
                    description: 'Tone, language, answer length, formatting, and clarification behavior.',
                    max_items: 20

  instruction_items :guardrails,
                    description: 'Refusal rules, escalation boundaries, source boundaries, safety limits, and things the assistant must not do.',
                    max_items: 20

  array :scenario_candidates,
        description: 'Review-stage specialized-agent candidates. These are also temporarily flattened into response guidelines.',
        max_items: 15 do
    object do
      string :title,
             description: 'Short scenario agent title for a distinct user-intent workflow.',
             max_length: 80
      string :description,
             description: 'When this specialized scenario should be used. This is shown to the orchestrator for routing.',
             max_length: 500
      string :instruction,
             description: 'How the specialized agent should handle the workflow. Include only evidence-backed markdown tool links. ' \
                          'Do not include confidence labels or review notes.',
             max_length: 2000
      string :response_guideline,
             description: 'Same-language, customer-visible response guideline that preserves this scenario behavior when flattened. ' \
                          'Do not include tool syntax, tool names, labels, private-note instructions, or internal implementation details.',
             max_length: 1000
      array :tool_ids,
            description: 'Available tool IDs explicitly referenced in instruction using markdown links. Empty when no tools are required.',
            max_items: 10,
            of: :string
    end
  end

  object :conversation_messages, description: 'Exact globally reusable customer-facing message copy found in instructions. ' \
                                              'Leave empty for conditional, placeholder, or workflow-specific copy.' do
    string :welcome_message, description: 'Exact globally reusable initial greeting copy from instructions, or empty string. ' \
                                          'Do not convert an instruction about greeting into message copy.',
                             max_length: 1000
    string :handoff_message,
           description: 'Exact globally reusable human-handoff message copy from instructions, or empty string. ' \
                        'Do not use scenario-specific, team-specific, placeholder, or conditional handoff copy.',
           max_length: 1000
    string :resolution_message,
           description: 'Exact globally reusable resolution/closing message copy from instructions, or empty string. ' \
                        'Do not use conditional or placeholder closing copy.',
           max_length: 1000
  end

  instruction_items :faq_document_candidates,
                    description: 'Only factual or product-specific knowledge candidates such as pricing, policy, setup, troubleshooting, ' \
                                 'or operational details.',
                    max_items: 25

  instruction_items :needs_review,
                    description: 'Unclear, conflicting, risky, duplicated, or uncertain content that needs human review. ' \
                                 'Include the reason in the item text.',
                    max_items: 20

  array :classification_notes, description: 'Short notes about important migration decisions or risks.', max_items: 10, of: :string
end
