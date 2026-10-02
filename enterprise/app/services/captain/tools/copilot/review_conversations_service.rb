class Captain::Tools::Copilot::ReviewConversationsService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'review_conversations'
  end
  description 'Start a background review of a saved conversation collection against the supplied criteria. Returns a run ID and coverage.'
  parameter :collection_id, type: :integer, description: 'Collection ID from get_data'
  parameter :criteria, type: :string, description: 'The exact requested checks, including how to classify each conversation'

  def execute(collection_id:, criteria:)
    raise ArgumentError, 'Criteria must be a nonempty string of at most 4000 characters' unless criteria.is_a?(String) &&
                                                                                                criteria.present? && criteria.size <= 4000

    collection = saved_run(collection_id, 'collection')
    review = run.with_lease(lease_token) do
      run.copilot_thread.copilot_runs.create_or_find_by!(copilot_run_step: step) do |record|
        record.assign_attributes(account: run.account, user: run.user, parent_run: collection, kind: 'review',
                                 context: collection.context.merge('criteria' => criteria))
      end
    end
    Captain::Copilot::ReviewJob.perform_later(review.id)
    review.receipt
  end
end
