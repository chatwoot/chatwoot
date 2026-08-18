class Captain::Routines::DslEvaluationSchema < RubyLLM::Schema
  string :status,
         enum: %w[valid correctable needs_clarification unsupported],
         description: 'Use correctable only for a material fidelity or executability defect, not an optional improvement.'
  string :summary, description: 'A concise explanation of the evaluation result.'

  array :corrections,
        max_items: 3,
        description: 'Only material defects that would cause missing, contradictory, invented, or unsupported behavior.' do
    object do
      string :path, description: 'The DSL path or concise description of the affected part.'
      string :problem, description: 'The concrete mismatch with an explicit administrator requirement or runtime capability.'
      string :suggestion, description: 'The smallest repair that restores fidelity without adding behavior.'
    end
  end

  array :questions, max_items: 3 do
    object do
      string :id, description: 'A stable snake_case identifier for the answer.'
      string :question
    end
  end

  array :missing_capabilities, max_items: 10 do
    object do
      string :requirement, description: 'The original requirement that cannot be fulfilled.'
      string :capability, description: 'The missing product behavior.'
    end
  end
end
