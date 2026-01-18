class LLMFormatter::LLMTextFormatterService
  def initialize(record)
    @record = record
  end

  def format(config = {})
    formatter_class = find_formatter
    formatter_class.new(@record).format(config)
  end

  private

  def find_formatter
    formatter_name = "LLMFormatter::#{@record.class.name}LLMFormatter"
    formatter_class = formatter_name.safe_constantize
    raise FormatterNotFoundError, "No formatter found for #{@record.class.name}" unless formatter_class

    formatter_class
  end
end
