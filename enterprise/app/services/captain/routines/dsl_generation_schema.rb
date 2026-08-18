class Captain::Routines::DslGenerationSchema < RubyLLM::Schema
  string :name, description: 'A short name for the Routine.'
  string :each, description: 'Snake_case name for the current conversation binding.'
  array :filters, max_items: 12, description: 'Deterministic conversation selection filters, with each field used at most once.' do
    object do
      string :field, enum: %w[status inbox contact assignee team waiting_for waiting_longer_than snooze_due priority labels created last_activity]
      any_of :value do
        string
        array of: :string
        object do
          string :ref, description: 'Reference to a pinned DSL resource.'
        end
      end
    end
  end
  string :record_instruction, description: 'The complete concise instruction for one autonomous record agent.'
  array :outcomes,
        min_items: 1,
        max_items: 12,
        of: :string,
        description: 'Minimal mutually exclusive snake_case outcomes, one for each final handling path requested by the administrator.'
  array :result_fields,
        max_items: 10,
        description: 'Task-specific business facts required by reduction. Never duplicate status, outcome, actions, or receipts.' do
    object do
      string :name, description: 'Unique snake_case field name.'
      string :type, enum: %w[string string_list enum boolean integer]
      string :description, description: 'What the field means and how the agent should populate it.'
      array :values,
            max_items: 20,
            of: :string,
            description: 'Allowed snake_case values for enum fields; otherwise an empty array.'
    end
  end
  string :collect_as, description: 'Snake_case name for the collected per-record results.'
  boolean :reduce, description: 'Whether the request needs cross-record reasoning or a final aggregate report.'
  string :reduction_instruction, description: 'Reducer instruction, or an empty string when reduce is false.'
  string :save_as, description: 'Snake_case reducer result binding, or an empty string when reduce is false.'
  string :summary, description: 'A short plain-language summary of what the Routine will do.'
end
