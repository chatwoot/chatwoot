module LLMFormattable
  extend ActiveSupport::Concern

  def to_llm_text(config = {})
    LLMFormatter::LLMTextFormatterService.new(self).format(config)
  end
end
