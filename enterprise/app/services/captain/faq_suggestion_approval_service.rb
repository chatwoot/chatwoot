class Captain::FaqSuggestionApprovalService
  def initialize(suggestion, attributes = {})
    @suggestion = suggestion
    @attributes = attributes
  end

  def perform
    suggestion.with_lock do
      raise ActiveRecord::RecordNotFound unless suggestion.open?

      suggestion.update!(attributes) if attributes.present?
      validate_language!

      response = suggestion.assistant.responses.create!(
        question: suggestion.question,
        answer: suggestion.answer,
        status: :approved
      )
      suggestion.approved!
      response
    end
  end

  private

  attr_reader :suggestion, :attributes

  def validate_language!
    return if base_language(suggestion.language) == base_language(suggestion.account.locale)

    suggestion.errors.add(:language, 'must match the account locale before approval')
    raise ActiveRecord::RecordInvalid, suggestion
  end

  def base_language(language)
    language.to_s.tr('-', '_').split('_').first
  end
end
