module LlmFormattable
  extend ActiveSupport::Concern

  def to_llm_text(include_contact_details: false)
    LlmFormatter::LlmTextFormatterService.new(self).format(
      include_contact_details: include_contact_details
    )
  end
end
