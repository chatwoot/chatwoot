class Captain::ResponseRewriteSchema < RubyLLM::Schema
  string :response, description: 'The shortened message to send to the user'
  string :reasoning, description: "Agent's thought process"
end
