class Captain::Tools::Copilot::ContinueReviewService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'continue_review'
  end
  description "Review the next #{CopilotRun::CONVERSATIONS_PER_TURN} conversations of an unfinished review with the same criteria. " \
              'Returns its coverage once the batch has finished. Findings stay on the same review ID.'
  parameter :review_id, type: :integer, description: 'ID of a review whose summary reports remaining conversations'

  def execute(review_id:)
    review = run.copilot_thread.saved_set(review_id, types: [CopilotRun::Review])
    run.with_lease(lease_token) { review.continue_review(tool_call) }
    Captain::Copilot::ReviewJob.perform_later(review.id)
    review.summary
  end
end
