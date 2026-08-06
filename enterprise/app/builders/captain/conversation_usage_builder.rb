# Lists the conversations where Captain used one durable knowledge record.
# Results use the shared reports drilldown serializer so the existing
# conversation cards can render them without a knowledge-specific card.
class Captain::ConversationUsageBuilder
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  USAGE_COLUMNS = %w[document_ids used_faq_ids].freeze
  DOCUMENT_CONVERSATION_USAGE_COUNT_SQL = <<~SQL.squish.freeze
    (
      SELECT COUNT(DISTINCT usage_sessions.subject_id)
      FROM agent_sessions AS usage_sessions
      WHERE usage_sessions.account_id = captain_documents.account_id
        AND usage_sessions.assistant_id = captain_documents.assistant_id
        AND usage_sessions.session_type = #{Captain::AgentSession.session_types.fetch('assistant')}
        AND usage_sessions.subject_type = 'Conversation'
        AND usage_sessions.document_ids @> jsonb_build_array(captain_documents.id)
    )
  SQL

  class << self
    def conversation_counts(resources, usage_column:)
      resources = resources.to_a
      return {} if resources.empty?

      usage_column = validate_usage_column(usage_column)
      resources_by_usage_key = resources.index_by { |resource| [resource.id.to_s, resource.assistant_id] }

      usage_count_rows(resources, usage_column).each_with_object({}) do |(resource_id, assistant_id, count), result|
        resource = resources_by_usage_key[[resource_id, assistant_id]]
        result[resource.id] = count if resource
      end
    end

    def order_documents_by_conversation_count(documents)
      documents.reorder(
        Arel.sql(
          "#{DOCUMENT_CONVERSATION_USAGE_COUNT_SQL} DESC, " \
          'captain_documents.updated_at DESC, captain_documents.id DESC'
        )
      )
    end

    private

    def usage_count_rows(resources, usage_column)
      usage_sessions(resources, usage_column)
        .where(knowledge_usage: { resource_id: resources.map { |resource| resource.id.to_s } })
        .group('knowledge_usage.resource_id', 'agent_sessions.assistant_id')
        .pluck(
          Arel.sql('knowledge_usage.resource_id'),
          Arel.sql('agent_sessions.assistant_id'),
          Arel.sql('COUNT(DISTINCT agent_sessions.subject_id)')
        )
    end

    def usage_sessions(resources, usage_column)
      Captain::AgentSession
        .session_assistant
        .where(
          account_id: resources.first.account_id,
          assistant_id: resources.map(&:assistant_id).uniq,
          subject_type: 'Conversation'
        )
        .joins(
          'CROSS JOIN LATERAL ' \
          "jsonb_array_elements_text(agent_sessions.#{usage_column}) " \
          'AS knowledge_usage(resource_id)'
        )
    end

    def validate_usage_column(usage_column)
      usage_column = usage_column.to_s
      return usage_column if USAGE_COLUMNS.include?(usage_column)

      raise ArgumentError, "Unsupported conversation usage column: #{usage_column}"
    end
  end

  def initialize(resource, params, usage_column:)
    @resource = resource
    @params = params
    @usage_column = usage_column.to_s
    raise ArgumentError, "Unsupported conversation usage column: #{@usage_column}" unless USAGE_COLUMNS.include?(@usage_column)
  end

  def build
    records = paginated_records.to_a

    {
      meta: {
        current_page: current_page,
        per_page: per_page,
        total_count: paginated_records.total_count,
        conversation_count: paginated_records.total_count
      },
      payload: records.map { |record| record_serializer(records).serialize(record) }
    }
  end

  private

  attr_reader :resource, :params, :usage_column

  def account = resource.account

  def paginated_records
    @paginated_records ||= conversations.page(current_page).per(per_page)
  end

  def conversations
    account.conversations
           .where(id: matching_sessions.select(:subject_id))
           .includes(:assignee, :contact, :inbox)
           .order(last_activity_at: :desc, id: :desc)
  end

  def matching_sessions
    account.captain_agent_sessions
           .session_assistant
           .where(assistant_id: resource.assistant_id, subject_type: 'Conversation')
           .where("agent_sessions.#{usage_column} @> ?", [resource.id].to_json)
  end

  def record_serializer(records)
    @record_serializer ||= V2::Reports::DrilldownRecordSerializer.new(account, 'knowledge_usage', false, records)
  end

  def current_page = [params[:page].to_i, DEFAULT_PAGE].max

  def per_page
    requested_per_page = params[:per_page].to_i
    requested_per_page = DEFAULT_PER_PAGE if requested_per_page <= 0

    [requested_per_page, MAX_PER_PAGE].min
  end
end
