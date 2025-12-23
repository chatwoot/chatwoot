RSpec.configure do |rspec|
  # Delay this in order to give users a chance to configure `expect_with`...
  rspec.before(:suite) do
    if defined?(RSpec::Matchers) &&
        RSpec::Matchers.configuration.respond_to?(:syntax) && # RSpec 4 dropped support for monkey-patching `should` syntax
        RSpec::Matchers.configuration.syntax.include?(:should) &&
        defined?(ActiveRecord::Associations)
      RSpec::Matchers.configuration.add_should_and_should_not_to ActiveRecord::Associations::CollectionProxy
    end
  end
end
