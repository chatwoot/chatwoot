class Captain::Copilot::CollectionService
  def initialize(run, tool_call:, token:)
    @run = run
    @tool_call = tool_call
    @token = token
  end

  # total is the exact number of matching records, while the saved selection stops at MAX_SELECTION. Counts per group
  # cover the same records as total.
  def create(resource:, filters:, from: nil, group_by: nil)
    raise ArgumentError, 'filters must be an object' unless filters.is_a?(Hash)

    selector = Captain::Copilot::Resources.build(resource, account: @run.account, user: @run.user)
    filters = selector.normalize(filters)
    source = @run.copilot_thread.saved_set(from) if from
    as_of = Time.current
    matching = selector.matching(filters, as_of: as_of, source: source)
    ids = selector.selected_ids(matching, filters)
    counted = filters['newest'] ? matching.where(id: ids) : matching
    groups = selector.group_counts(counted, filters, as_of, group_by) if group_by
    collection = persist_collection(resource, filters, ids, as_of, source)
    result = collection.summary.merge(collection_id: collection.id, resource: resource, as_of: collection.as_of.iso8601,
                                      total: counted.count)
    groups ? result.merge(group_by: group_by, groups: groups) : result
  end

  private

  def persist_collection(resource, filters, ids, as_of, source)
    @run.with_lease(@token) do
      @run.copilot_thread.copilot_runs.create_or_find_by!(copilot_tool_call: @tool_call) do |record|
        record.assign_attributes(account: @run.account, user: @run.user, source_run: source, kind: :collection, status: :completed,
                                 context: { resource: resource, filters: filters, selected_ids: ids.first(CopilotRun::MAX_SELECTION),
                                            as_of: as_of.iso8601(6), selection_truncated: ids.size > CopilotRun::MAX_SELECTION })
      end
    end
  end
end
