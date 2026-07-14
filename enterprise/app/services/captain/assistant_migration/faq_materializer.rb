class Captain::AssistantMigration::FaqMaterializer
  pattr_initialize [:assistant!, :candidates!]

  def changes
    @changes ||= candidates.each_with_object({ create: [], approve: [] }) do |candidate, result|
      categorize(candidate, result)
    end.compact_blank.presence
  end

  def apply(changes)
    Array(changes[:approve]).each do |candidate|
      assistant.responses.find(candidate[:id]).update!(status: :approved)
    end

    Array(changes[:create]).each do |candidate|
      assistant.responses.create!(candidate.slice('question', 'answer', 'status'))
    end
  end

  private

  def categorize(candidate, result)
    existing_responses = assistant.responses.where(question: candidate['question']).to_a
    ensure_no_conflict!(candidate, existing_responses)

    existing_response = existing_responses.find { |response| response.answer == candidate['answer'] }
    return result[:approve] << approval_change(existing_response) if existing_response&.pending?
    return if existing_response

    result[:create] << candidate.merge('status' => 'approved')
  end

  def ensure_no_conflict!(candidate, existing_responses)
    return if existing_responses.all? { |response| response.answer == candidate['answer'] }

    raise ArgumentError, "FAQ candidate conflicts with an existing FAQ: #{candidate['question']}"
  end

  def approval_change(response)
    { id: response.id, question: response.question, answer: response.answer }
  end
end
