# A custom tool where an admin or an agent is the user: the playground and reply suggestions
class Captain::Tools::CopilotHttpTool < Captain::Tools::HttpTool
  include Captain::Tools::CopilotSourcedArguments

  def self.model_fills_verified_values?
    true
  end

  private

  def sourced_tool
    @custom_tool
  end
end
