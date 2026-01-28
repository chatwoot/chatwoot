module Captain::Tools::Instrumentation
  extend ActiveSupport::Concern
  include Integrations::LlmInstrumentation

  def execute(**args)
    instrument_tool_call(name, args) do
      super
    end
  end
end
