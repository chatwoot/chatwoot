if defined?(ActiveRecord::Relation) && defined?(RSpec::Matchers::BuiltIn::OperatorMatcher) # RSpec 4 removed OperatorMatcher
  RSpec::Matchers::BuiltIn::OperatorMatcher.register(ActiveRecord::Relation, '=~', RSpec::Matchers::BuiltIn::ContainExactly)
end
