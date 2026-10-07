class Captain::FaqSuggestionApprovalService
  def initialize(suggestion, attributes = {})
    @suggestion = suggestion
    @attributes = attributes
  end

  def perform
    suggestion.with_lock do
      raise ActiveRecord::RecordNotFound unless suggestion.open?

      suggestion.update!(attributes) if attributes.present?

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
end
