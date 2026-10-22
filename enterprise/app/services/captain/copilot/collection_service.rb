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
    source = @run.copilot_thread.saved_set(from) if from
    filters = selector.normalize(filters, source: source)
    as_of = Time.current
    matching = selector.matching(filters, as_of: as_of, source: source)
    ids = selector.selected_ids(matching, filters)
    counted = filters['newest'] ? matching.where(id: ids) : matching
    groups = selector.group_counts(counted, filters, as_of, group_by) if group_by
    collection = persist_collection(resource, filters, ids, as_of, source)
    result = collection_result(collection, resource, counted.count, selector.note)
    groups ? result.merge(group_by: group_by, groups: groups) : result
  end

  private

  # The resource's note, such as a date range it chose because none was given, goes to the model with the total.
  def collection_result(collection, resource, total, note)
    result = collection.summary.merge(collection_id: collection.id, resource: resource, as_of: collection.as_of.iso8601, total: total)
    note ? result.merge(note: note) : result
  end

  # A selection made from a cut-off saved set is cut off too, because the records the saved set left out were never checked.
  def persist_collection(resource, filters, ids, as_of, source)
    truncated = ids.size > CopilotRun::MAX_SELECTION || (source.present? && source.selection_truncated?)
    @run.with_lease(@token) do
      CopilotRun::Collection.create_or_find_by!(copilot_tool_call: @tool_call) do |record|
        record.assign_attributes(copilot_thread: @run.copilot_thread, account: @run.account, user: @run.user, source_run: source,
                                 status: :completed,
                                 context: { resource: resource, filters: filters, selected_ids: ids.first(CopilotRun::MAX_SELECTION),
                                            as_of: as_of.iso8601(6), selection_truncated: truncated })
      end
    end
  end
end
