# Lists the conversations where Captain used one durable knowledge record.
# Results use the shared reports drilldown serializer so the existing
# conversation cards can render them without a knowledge-specific card.
class Captain::ConversationUsageBuilder
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  USAGE_COLUMNS = %w[document_ids used_faq_ids].freeze

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

    def order_documents_by_conversation_count(documents, account_id:, assistant_id: nil)
      usage_counts_sql = document_usage_counts(account_id, assistant_id).to_sql
      documents_table = Captain::Document.arel_table
      usage_counts = Arel::Table.new('captain_document_usage')
      conversation_count = Arel::Nodes::NamedFunction.new(
        'COALESCE',
        [usage_counts[:conversation_count].maximum, Arel::Nodes.build_quoted(0)]
      )

      documents
        .joins(
          <<~SQL.squish
            LEFT JOIN (#{usage_counts_sql}) AS captain_document_usage
              ON captain_document_usage.resource_id = captain_documents.id::text
              AND captain_document_usage.assistant_id = captain_documents.assistant_id
          SQL
        )
        .group(documents_table[:id])
        .reorder(conversation_count.desc, documents_table[:updated_at].desc, documents_table[:id].desc)
    end

    private

    def usage_count_rows(resources, usage_column)
      resources.each_slice(DEFAULT_PER_PAGE).flat_map do |batch|
        Captain::AgentSession.connection.select_rows(usage_count_sql(batch, usage_column))
      end
    end

    # Each materialized query covers at most one 25-record API page. Keeping one
    # constant containment predicate per record lets PostgreSQL use the JSONB
    # GIN index before it checks whether each conversation still exists.
    def usage_count_sql(resources, usage_column)
      ctes = []
      count_queries = []

      resources.uniq { |resource| [resource.id, resource.assistant_id] }.each_with_index do |resource, index|
        cte_name = "matching_sessions_#{index}"
        ctes << "#{cte_name} AS MATERIALIZED (#{indexed_usage_sessions(resource, usage_column).to_sql})"
        count_queries << usage_count_query(resource, cte_name)
      end

      "WITH #{ctes.join(', ')} #{count_queries.join(' UNION ALL ')}"
    end

    def indexed_usage_sessions(resource, usage_column)
      Captain::AgentSession.session_assistant
                           .with_delivered_answer
                           .where(
                             account_id: resource.account_id,
                             assistant_id: resource.assistant_id,
                             subject_type: 'Conversation'
                           )
                           .where(Captain::AgentSession.arel_table[usage_column].contains([resource.id]))
                           .select(:subject_id, :assistant_id, :account_id)
    end

    def usage_count_query(resource, cte_name)
      sessions = Arel::Table.new(cte_name)
      query = sessions.project(
        Arel::Nodes.build_quoted(resource.id.to_s).as('resource_id'),
        sessions[:assistant_id],
        sessions[:subject_id].count(true)
      )
      query.join_sources.concat(existing_conversation_join(sessions))
      query.group(sessions[:assistant_id]).to_sql
    end

    def document_usage_counts(account_id, assistant_id)
      sessions_table = Captain::AgentSession.arel_table
      knowledge_usage = Arel::Table.new('knowledge_usage')
      sessions = Captain::AgentSession.session_assistant
                                      .with_delivered_answer
                                      .where(account_id: account_id, subject_type: 'Conversation')
      sessions = sessions.where(assistant_id: assistant_id) if assistant_id.present?

      sessions
        .joins(existing_conversation_join(sessions_table))
        .joins(
          'CROSS JOIN LATERAL ' \
          'jsonb_array_elements_text(agent_sessions.document_ids) AS knowledge_usage(resource_id)'
        )
        .select(
          sessions_table[:assistant_id],
          knowledge_usage[:resource_id],
          sessions_table[:subject_id].count(true).as('conversation_count')
        )
        .group(sessions_table[:assistant_id], knowledge_usage[:resource_id])
    end

    def existing_conversation_join(sessions)
      conversations = Conversation.arel_table.alias('usage_conversations')
      join_condition = conversations[:id].eq(sessions[:subject_id])
                                         .and(conversations[:account_id].eq(sessions[:account_id]))

      sessions.join(conversations).on(join_condition).join_sources
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
           .with_delivered_answer
           .where(assistant_id: resource.assistant_id, subject_type: 'Conversation')
           .where(Captain::AgentSession.arel_table[usage_column].contains([resource.id]))
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
