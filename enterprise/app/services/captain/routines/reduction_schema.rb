class Captain::Routines::ReductionSchema < RubyLLM::Schema
  string :summary, description: 'The requested cross-record summary grounded in the supplied record results and action receipts.'
end
