module LlmFormattable
  extend ActiveSupport::Concern

  def to_llm_text(config = {})
    LlmFormatter::LlmTextFormatterService.new(self).format(config)
  end
end
