class Captain::Tools::Copilot::ContinueReviewService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'continue_review'
  end
  description "Review the next #{CopilotRun::REVIEW_BUDGET} conversations of an unfinished review with the same criteria. " \
              'Returns its coverage once the batch has finished. Findings stay on the same review ID.'
  parameter :review_id, type: :integer, description: 'ID of a review whose receipt reports remaining conversations'

  def execute(review_id:)
    review = saved_run(review_id, 'review')
    run.with_lease(lease_token) { review.continue_review(step) }
    Captain::Copilot::ReviewJob.perform_later(review.id)
    review.receipt
  end
end
