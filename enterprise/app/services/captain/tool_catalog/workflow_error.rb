class Captain::ToolCatalog::WorkflowError < StandardError
  attr_reader :code

  def initialize(code, message = code.humanize)
    @code = code
    super(message)
  end
end
