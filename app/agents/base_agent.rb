class BaseAgent
  # Base class for all agents providing common functionality
  # Agents should inherit from this class and implement the #run method
  #
  # Usage:
  #   class MyAgent < BaseAgent
  #
  #     MODEL = 'gpt-4o-mini'
  #     TEMPERATURE = 0.7
  #
  #     def initialize(user)
  #       @user = user
  #     end
  #
  #     def run
  #       # Agent logic here
  #       success_response(result)
  #     end
  #
  #     private
  #
  #     def system_prompt
  #       "Your system instructions"
  #     end
  #
  #     def user_prompt
  #       "Your user prompt"
  #     end
  #
  #     def schema
  #       RubyLLM::Schema.create do
  #         string :field, required: true
  #       end
  #     end
  #   end
  #
  #   # Running the agent:
  #   result = MyAgent.run(user, params)              # Class method (recommended)
  #   result = MyAgent.new(user, params).run          # Instance method

  MODEL = 'gpt-4o-mini'
  TEMPERATURE = 0.7

  # Class method to run agent without instantiating first
  # Usage: ProductivityAgent.run(user, date)
  def self.run(*, **)
    new(*, **).run
  end

  # Main entry point - must be implemented by subclasses
  def run
    raise NotImplementedError, "#{self.class} must implement #run"
  end

  def system_prompt
    nil
  end

  def user_prompt
    raise NotImplementedError, "#{self.class} must implement #user_prompt"
  end

  def schema
    nil
  end

  private

  # Execute LLM chat with optional schema
  def execute
    chat = RubyLLM.chat.with_model(self.class::MODEL).with_temperature(self.class::TEMPERATURE)

    chat = chat.with_instructions(system_prompt) if system_prompt
    chat = chat.with_schema(schema) if schema

    response = chat.ask(user_prompt)
    response.content.with_indifferent_access
  rescue StandardError => e
    log_error('Agent execution failed', e)
    nil
  end

  # Log error with context
  def log_error(message, error = nil)
    error_msg = "[#{self.class.name}] #{message}"
    error_msg += ": #{error.message}\n#{error.backtrace.join("\n")}" if error
    Rails.logger.error(error_msg)
  end

  # Log info
  def log_info(message)
    Rails.logger.info("[#{self.class.name}] #{message}")
  end

  # Success response format
  def success_response(data, message: nil)
    response = { success: true, data: data }
    response[:message] = message if message
    response
  end

  # Error response format
  def error_response(error_message)
    { success: false, error: error_message }
  end
end
