class Captain::Tools::Copilot::ReviewConversationsService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'review_conversations'
  end
  description "Review a saved conversation collection one conversation at a time, newest first, up to #{CopilotRun::REVIEW_BUDGET} per turn. " \
              'Returns the review ID and coverage, including conversations remaining, once the batch has finished.'
  parameter :collection_id, type: :integer, description: 'Collection ID from get_data'
  parameter :criteria, type: :string, description: 'The exact requested checks, including how to classify each conversation'
  parameter :match, type: :string, required: false,
                    description: 'Optional yes or no question. Conversations that clearly do not satisfy it are screened out before review'

  def execute(collection_id:, criteria:, match: nil)
    validate_text!(criteria, 'Criteria', 4000)
    if match
      validate_text!(match, 'Match', 500)
      raise ArgumentError, 'Screening is unavailable. Retry without match.' unless Captain::Copilot::ScreeningService.available?
    end

    collection = review_source(collection_id)
    review = run.with_lease(lease_token) do
      run.copilot_thread.copilot_runs.create_or_find_by!(copilot_run_step: step) do |record|
        record.assign_attributes(account: run.account, user: run.user, parent_run: collection, kind: 'review',
                                 context: collection.context.merge('criteria' => criteria, 'match' => match,
                                                                   'budget' => CopilotRun::REVIEW_BUDGET).compact)
      end
    end
    Captain::Copilot::ReviewJob.perform_later(review.id)
    review.receipt
  end

  private

  def review_source(collection_id)
    collection = saved_run(collection_id, 'collection')
    return collection if collection.resource == 'conversations'

    raise ArgumentError, "Reviews read conversations. Call get_data with resource conversations and from #{collection.id} first."
  end

  def validate_text!(value, label, limit)
    return if value.is_a?(String) && value.present? && value.size <= limit

    raise ArgumentError, "#{label} must be a nonempty string of at most #{limit} characters"
  end
end
