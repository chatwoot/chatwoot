class Captain::Copilot::DataService
  include Captain::Copilot::ConversationAccess

  FILTER_SCHEMA = {
    type: 'object', additionalProperties: false,
    properties: {
      since: { type: 'string', format: 'date-time' }, before: { type: 'string', format: 'date-time' },
      date_field: { type: 'string', enum: %w[created_at last_activity_at] },
      status: { type: 'string', enum: Conversation.statuses.keys }, priority: { type: 'string', enum: Conversation.priorities.keys },
      inbox_id: { type: 'integer' }, assignee_id: { type: 'integer' }, contact_id: { type: 'integer' },
      labels: { type: 'array', items: { type: 'string' } }, limit: { type: 'integer', minimum: 1, maximum: CopilotRun::MAX_SELECTION }
    }
  }.deep_stringify_keys.freeze

  def initialize(run, step:, token:)
    @run = run
    @step = step
    @token = token
  end

  def retrieve(resource:, filters:)
    raise ArgumentError, 'Supported resource: conversations' unless resource == 'conversations'
    raise ArgumentError, 'filters must be an object' unless filters.is_a?(Hash)

    filters = filters.deep_stringify_keys
    raise ArgumentError, 'Invalid conversation filters' unless JSONSchemer.schema(FILTER_SCHEMA).valid?(filters)

    boundary = Time.current
    filters = filters.stringify_keys.reverse_merge('date_field' => 'last_activity_at', 'limit' => 100)
    ids = filtered_conversations(filters, boundary).order(id: :desc).limit(filters['limit'] + 1).pluck(:id)
    collection = persist_collection(filters, ids, boundary)
    collection.receipt.merge(collection_id: collection.id, resource: resource, boundary_at: collection.boundary_at.iso8601)
  end

  private

  def persist_collection(filters, ids, boundary)
    @run.with_lease(@token) do
      @run.copilot_thread.copilot_runs.create_or_find_by!(copilot_run_step: @step) do |record|
        record.assign_attributes(account: @run.account, user: @run.user, parent_run: @run, kind: 'collection', status: 'completed',
                                 context: { filters: filters, selected_ids: ids.first(filters['limit']), boundary_at: boundary.iso8601(6),
                                            selection_truncated: ids.size > filters['limit'] })
      end
    end
  end

  def filtered_conversations(filters, boundary)
    scope = accessible_conversations(account: @run.account, user: @run.user)
    scope = apply_dates(scope, filters, boundary)
    scope = scope.where(filters.slice('status', 'priority', 'inbox_id', 'assignee_id', 'contact_id'))
    scope = scope.tagged_with(filters['labels'], any: true) if filters['labels'].present?
    scope
  end

  def apply_dates(scope, filters, boundary)
    since = Time.iso8601(filters['since']) if filters['since']
    before = filters['before'] ? Time.iso8601(filters['before']) : boundary
    raise ArgumentError, 'since must be earlier than before' if since && since >= before
    raise ArgumentError, 'before cannot be in the future' if before > boundary

    field = Conversation.arel_table[filters['date_field']]
    scope = scope.where(field.lt(before))
    scope = scope.where(field.gteq(since)) if since
    scope
  end
end
