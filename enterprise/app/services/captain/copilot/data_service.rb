class Captain::Copilot::DataService
  def initialize(run, step:, token:)
    @run = run
    @step = step
    @token = token
  end

  # total is the exact number of matching records, while the saved selection stops at MAX_SELECTION. Counts per group
  # cover the same records as total.
  def retrieve(resource:, filters:, from: nil, group_by: nil)
    raise ArgumentError, 'filters must be an object' unless filters.is_a?(Hash)

    selector = Captain::Copilot::Resources.build(resource, account: @run.account, user: @run.user)
    filters = selector.normalize(filters)
    source = saved_set(from) if from
    boundary = Time.current
    matching = selector.matching(filters, boundary: boundary, source: source)
    ids = selector.selected_ids(matching, filters)
    counted = filters['newest'] ? matching.where(id: ids) : matching
    groups = selector.group_counts(counted, filters, boundary, group_by) if group_by
    collection = persist_collection(resource, filters, ids, boundary, source)
    result = collection.receipt.merge(collection_id: collection.id, resource: resource, boundary_at: collection.boundary_at.iso8601,
                                      total: counted.count)
    groups ? result.merge(group_by: group_by, groups: groups) : result
  end

  private

  def saved_set(id)
    @run.copilot_thread.copilot_runs.where(account: @run.account, user: @run.user, kind: %w[collection review]).find(id)
  end

  def persist_collection(resource, filters, ids, boundary, source)
    @run.with_lease(@token) do
      @run.copilot_thread.copilot_runs.create_or_find_by!(copilot_run_step: @step) do |record|
        record.assign_attributes(account: @run.account, user: @run.user, parent_run: @run, kind: 'collection', status: 'completed',
                                 context: { resource: resource, filters: filters, source_id: source&.id,
                                            selected_ids: ids.first(CopilotRun::MAX_SELECTION), boundary_at: boundary.iso8601(6),
                                            selection_truncated: ids.size > CopilotRun::MAX_SELECTION }.compact)
      end
    end
  end
end
