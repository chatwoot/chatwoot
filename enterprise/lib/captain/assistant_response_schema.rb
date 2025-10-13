# frozen_string_literal: true

class Captain::AssistantResponseSchema < RubyLLM::Schema
  string :response, description: 'The message to send to the user'
  string :reasoning, description: "Agent's thought process tying the ARQ back to the final reply"

  object :arq_plan, description: 'Attentive Reasoning Query plan used before producing the response' do
    array :instructions_to_restate, of: :string,
                                    description: 'Ordered guardrails, guidelines, tool duties, and routing expectations restated prior to reply'
    array :response_compliance_checklist, of: :string,
                                          description: 'Yes/no checklist confirming the response satisfies every critical obligation'
    array :scenario_routing_candidates, of: :string,
                                        description: 'Scenarios evaluated with quick notes on whether they should receive the handoff'
    string :handoff_decision, description: 'Scenario key selected for handoff, or "self" when responding directly'
    string :handoff_rationale, description: 'Why the chosen handoff path best serves the request while respecting constraints'
    boolean :ready_to_respond,
            description: 'Indicates all checklist items are satisfied and the assistant is cleared to draft the response'
    string :notes, description: '≤20 word justification summarizing how obligations will be met or what is outstanding'
  end
end
