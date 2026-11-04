# A custom tool in a conversation where a customer is the user
class Captain::Tools::PublicHttpTool < Captain::Tools::HttpTool
  include Captain::Tools::PublicSourcedArguments

  private

  def sourced_tool
    @custom_tool
  end
end
