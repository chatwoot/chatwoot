# frozen_string_literal: true

class Captain::ScenarioResponseSchema < RubyLLM::Schema
  string :response, description: 'Customer-facing message produced by the scenario agent'
  string :reasoning, description: 'Short explanation connecting the ARQ plan to the final response or handoff'

  object :arq_plan, description: 'Scenario Attentive Reasoning Query captured before responding' do
    array :instructions_to_restate, of: :string,
                                    description: 'Concrete guardrails, scenario instructions, and tool rules reiterated for this turn'
    array :response_compliance_checklist, of: :string,
                                          description: 'Yes/no questions verifying the response adheres to obligations'
    array :scope_risks, of: :string,
                        description: 'Potential conversation needs outside this scenario’s scope (or a “None identified” entry)'
    array :tool_plan, of: :string,
                      description: 'Planned tool calls in order, each with a justification or “none”'
    string :handoff_back_decision,
           description: 'Either "handoff_to_<assistant_key>" to return control or "stay" to respond directly'
    string :handoff_back_rationale,
           description: 'Brief justification for staying or handing back to the assistant'
    boolean :ready_to_respond,
            description: 'True only when checklist is satisfied and scope risks are addressed'
    string :notes,
           description: '≤20 word summary of how obligations will be met or what remains open if not ready'
  end
end
