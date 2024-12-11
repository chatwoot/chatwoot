module LlmFormattable
  extend ActiveSupport::Concern

  def to_llm_text
    LlmFormatter::LlmTextFormatterService.new(self).format
  end
end
