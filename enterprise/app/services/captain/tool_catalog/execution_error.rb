class Captain::ToolCatalog::ExecutionError < StandardError
  CATEGORIES = %w[
    authentication authorization validation not_found rate_limit timeout upstream disconnected invalid_response
  ].freeze

  attr_reader :category, :code

  def initialize(category, code)
    raise ArgumentError, "Unknown execution error category: #{category}" unless CATEGORIES.include?(category)

    @category = category
    @code = code
    super(code)
  end

  def model_response
    { error: { category: category, code: code } }
  end
end
