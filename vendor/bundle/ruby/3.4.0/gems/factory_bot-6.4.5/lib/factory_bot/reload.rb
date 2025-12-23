module FactoryBot
  def self.reload
    Internal.reset_configuration
    Internal.register_default_strategies
    find_definitions
  end
end
