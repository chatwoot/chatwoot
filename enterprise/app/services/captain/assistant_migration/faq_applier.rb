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
    existing_answers = assistant.responses.approved.where(question: candidate['question']).pluck(:answer)
    planned_answers = result[:create].filter_map do |response|
      response['answer'] if response['question'] == candidate['question']
    end
    answers = existing_answers + planned_answers

    ensure_no_conflict!(candidate, answers)
    return if answers.include?(candidate['answer'])

    result[:create] << candidate.merge('status' => 'approved')
  end

  def ensure_no_conflict!(candidate, answers)
    return if answers.all?(candidate['answer'])

    raise ArgumentError, "FAQ candidate conflicts with an existing FAQ: #{candidate['question']}"
  end
end
