class Captain::Routines::SemanticPlanGenerationSchema < RubyLLM::Schema
  string :plan_json, description: 'The complete semantic Routine plan as valid JSON.'
  string :summary, description: 'A short plain-language summary of the plan.'
end
