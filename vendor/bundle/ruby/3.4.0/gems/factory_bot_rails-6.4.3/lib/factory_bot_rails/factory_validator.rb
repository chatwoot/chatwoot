module FactoryBotRails
  class FactoryValidator
    def initialize(validators = [])
      @validators = Array(validators)
    end

    def add_validator(validator)
      @validators << validator
    end

    def run
      ActiveSupport::Notifications.subscribe("factory_bot.compile_factory", &validate_compiled_factory)
    end

    private

    def validate_compiled_factory
      proc do |event|
        @validators.each { |validator| validator.validate!(event.payload) }
      end
    end
  end
end
