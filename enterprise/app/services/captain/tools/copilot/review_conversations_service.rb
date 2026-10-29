class Captain::Tools::Copilot::ReviewConversationsService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'review_conversations'
  end
  description 'Review a saved conversation collection one conversation at a time, in the collection\'s order: newest first, oldest ' \
              "first with oldest_first, or spread across the period with sample, up to #{CopilotRun::CONVERSATIONS_PER_TURN} per turn. " \
              'Returns the review ID and coverage, including conversations remaining, once the batch has finished.'
  parameter :collection_id, type: :integer, description: 'Collection ID from get_data'
  parameter :criteria, type: :string, description: 'The exact requested checks, including how to classify each conversation'
  parameter :question, type: :string, required: false,
                       description: 'Only when the agent asked about part of the selected conversations. Leave it out when every ' \
                                    'selected conversation is in scope. Conversations whose answer is clearly no are screened out ' \
                                    'before review'
  parameter :reference, type: :string, required: false,
                        description: 'Material each conversation is judged against, taken from earlier tool results'

  # CopilotRun::Review checks criteria, question and reference when it is saved.
  def execute(collection_id:, criteria:, question: nil, reference: nil)
    raise ArgumentError, 'Screening is unavailable. Retry without question.' if question && !Captain::Copilot::ScreeningService.available?

    review = create_review(review_source(collection_id), criteria, question, reference)
    Captain::Copilot::ReviewJob.perform_later(review.id)
    review.summary
  end

  private

  # The agent's own message is saved with the model's question and criteria, so the reviewer can follow the agent's words.
  # The selection stays on the collection, which the review reads as its source run. A replayed call finds its review.
  def create_review(collection, criteria, question, reference)
    context = { 'request' => run.copilot_message.message['content'], 'criteria' => criteria, 'question' => question,
                'reference' => reference }.compact
    run.with_lease(lease_token) do
      tool_call.background_run || CopilotRun::Review.create!(
        copilot_thread: run.copilot_thread, copilot_tool_call: tool_call, account: run.account, user: run.user, source_run: collection,
        context: context.merge('turn_start' => 0, 'turn_start_matched' => 0, 'turn_start_failed' => 0, 'turn_limit' => run.review_budget!)
      )
    end
  end

  def review_source(collection_id)
    collection = run.copilot_thread.saved_set(collection_id, types: [CopilotRun::Collection])
    return collection if collection.resource == 'conversations'

    raise ArgumentError, "Reviews read conversations. Call get_data with resource conversations and from #{collection.id} first."
  end
end
