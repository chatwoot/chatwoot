# TODO: Wrap the schema lib under ai-agents
# So we can extend it as Agents::Schema
class Captain::ResponseSchema < RubyLLM::Schema
  string :response, description: 'The message to send to the user'
  string :reasoning, description: "Agent's thought process"
  object :arq_plan, description: 'Attentive Reasoning Query plan used to prepare the response' do
    array :instructions_to_restate, of: :string,
                                    description: 'Ordered list of concrete guardrails, guidelines, tool rules, and routing expectations to repeat before responding'
    array :response_compliance_checklist, of: :string, description: 'Yes/no questions confirming the response satisfies each critical obligation'
    boolean :ready_to_respond, description: 'Indicates whether the checklist is fully satisfied prior to finalizing the response'
    string :notes, description: 'Short justification (≤20 words) explaining how the checklist is or will be satisfied'
  end
end
