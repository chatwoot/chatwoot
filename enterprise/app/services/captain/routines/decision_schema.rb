class Captain::Routines::DecisionSchema
  def self.for(choices)
    Class.new(RubyLLM::Schema).tap do |schema|
      schema.string :choice, enum: choices, description: 'Exactly one of the permitted decision outcomes.'
      schema.string :reason, description: 'A concise explanation grounded only in the supplied context.'
    end
  end
end
