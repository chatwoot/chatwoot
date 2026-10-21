class Captain::Tools::Copilot::ReviewConversationsService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'review_conversations'
  end
  description 'Review a saved conversation collection one conversation at a time, newest first, ' \
              "up to #{CopilotRun::CONVERSATIONS_PER_TURN} per turn. " \
              'Returns the review ID and coverage, including conversations remaining, once the batch has finished.'
  parameter :collection_id, type: :integer, description: 'Collection ID from get_data'
  parameter :criteria, type: :string, description: 'The exact requested checks, including how to classify each conversation'
  parameter :question, type: :string, required: false,
                       description: 'Optional yes or no question. Conversations whose answer is clearly no are screened out before review'

  def execute(collection_id:, criteria:, question: nil)
    validate_text!(criteria, 'Criteria', 4000)
    if question
      validate_text!(question, 'Question', 500)
      raise ArgumentError, 'Screening is unavailable. Retry without question.' unless Captain::Copilot::ScreeningService.available?
    end

    review = create_review(review_source(collection_id), criteria, question)
    Captain::Copilot::ReviewJob.perform_later(review.id)
    review.summary
  end

  private

  # The agent's own message is saved with the model's question and criteria, so the reviewer can follow the agent's words.
  # The selection stays on the collection, which the review reads as its source run. A replayed call finds its review.
  def create_review(collection, criteria, question)
    context = { 'request' => run.copilot_message.message['content'], 'criteria' => criteria, 'question' => question }.compact
    run.with_lease(lease_token) do
      tool_call.background_run || CopilotRun::Review.create!(
        copilot_thread: run.copilot_thread, copilot_tool_call: tool_call, account: run.account, user: run.user, source_run: collection,
        context: context.merge('turn_start' => 0, 'turn_limit' => run.review_budget!)
      )
    end
  end

  def review_source(collection_id)
    collection = run.copilot_thread.saved_set(collection_id, types: [CopilotRun::Collection])
    return collection if collection.resource == 'conversations'

    raise ArgumentError, "Reviews read conversations. Call get_data with resource conversations and from #{collection.id} first."
  end

  def validate_text!(value, label, limit)
    return if value.is_a?(String) && value.present? && value.size <= limit

    raise ArgumentError, "#{label} must be a nonempty string of at most #{limit} characters"
  end
end
