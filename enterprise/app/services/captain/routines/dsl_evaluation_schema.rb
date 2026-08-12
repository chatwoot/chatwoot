class Captain::Routines::DslEvaluationSchema < RubyLLM::Schema
  string :status, enum: %w[valid correctable needs_clarification]
  string :summary, description: 'A concise explanation of the evaluation result.'

  array :corrections, max_items: 10 do
    object do
      string :path, description: 'JSON Pointer or a concise description of the affected DSL location.'
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
end
