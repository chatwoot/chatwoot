module Captain::Tools::Instrumentation
  extend ActiveSupport::Concern
  include Integrations::LlmInstrumentation

  def execute(**args)
    instrument_tool_call(tool_name, args) do
      super
    end
  end

  private

  def tool_name
    self.class.name.demodulize.underscore.delete_suffix('_service')
  end
end
