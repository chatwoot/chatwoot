class Captain::Routines::DslGenerationSchema < RubyLLM::Schema
  string :dsl_json, description: 'The complete Captain Routine DSL as valid JSON.'
  string :summary, description: 'A short plain-language summary of what the routine will do.'
end
