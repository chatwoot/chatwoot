class Captain::ToolCatalog::EvaluationTool < RubyLLM::Tool
  def initialize(definition)
    @definition = definition
    super()
  end

  def name
    definition.fetch('name')
  end

  def description
    definition.fetch('description')
  end

  def params_schema
    definition.fetch('input_schema')
  end

  def execute(**_params)
    halt('Tool selection recorded.')
  end

  private

  attr_reader :definition
end
