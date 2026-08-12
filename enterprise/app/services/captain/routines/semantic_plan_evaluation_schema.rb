class Captain::Routines::SemanticPlanEvaluationSchema < RubyLLM::Schema
  string :status, enum: %w[valid correctable needs_clarification unsupported]
  string :summary, description: 'A concise explanation of the evaluation result.'

  array :corrections, max_items: 10 do
    object do
      string :path, description: 'The plan step ID or concise description of the affected part.'
      string :problem
      string :suggestion
    end
  end

  array :questions, max_items: 5 do
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
