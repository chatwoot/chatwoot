class Captain::AssistantMigration::FaqApplier
  pattr_initialize [:assistant!, :candidates!]

  def changes
    @changes ||= candidates.each_with_object({ create: [] }) do |candidate, result|
      categorize(candidate, result)
    end.compact_blank.presence
  end

  def apply(changes)
    Array(changes[:create]).each do |candidate|
      assistant.responses.create!(candidate.slice('question', 'answer', 'status'))
    end
  end

  private

  def categorize(candidate, result)
    existing_responses = assistant.responses.approved.where(question: candidate['question']).to_a
    ensure_no_conflict!(candidate, existing_responses)

    return if existing_responses.any? { |response| response.answer == candidate['answer'] }

    result[:create] << candidate.merge('status' => 'approved')
  end

  def ensure_no_conflict!(candidate, existing_responses)
    return if existing_responses.all? { |response| response.answer == candidate['answer'] }

    raise ArgumentError, "FAQ candidate conflicts with an existing FAQ: #{candidate['question']}"
  end
end
