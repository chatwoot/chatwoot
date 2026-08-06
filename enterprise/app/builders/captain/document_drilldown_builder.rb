# Lists the conversations where Captain retrieved knowledge from one document.
# Results use the shared reports drilldown serializer so the existing
# conversation cards can render them without a document-specific card.
class Captain::DocumentDrilldownBuilder
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  CONVERSATION_USAGE_COUNT_SQL = <<~SQL.squish.freeze
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

  pattr_initialize :document, :params

  class << self
    def conversation_counts(documents)
      documents = documents.to_a
      return {} if documents.empty?

      usage_count_rows(documents).to_h
    end

    def order_by_conversation_count(documents)
      documents.reorder(
        Arel.sql(
          "#{CONVERSATION_USAGE_COUNT_SQL} DESC, " \
          'captain_documents.updated_at DESC, captain_documents.id DESC'
        )
      )
    end

    private

    def usage_count_rows(documents)
      usage_sessions(documents)
        .where(usage_documents: { id: documents.map(&:id) })
        .group('usage_documents.id')
        .pluck(
          Arel.sql('usage_documents.id'),
          Arel.sql('COUNT(DISTINCT agent_sessions.subject_id)')
        )
    end

    def usage_sessions(documents)
      Captain::AgentSession
        .session_assistant
        .where(
          account_id: documents.first.account_id,
          assistant_id: documents.map(&:assistant_id).uniq,
          subject_type: 'Conversation'
        )
        .joins(
          'CROSS JOIN LATERAL ' \
          'jsonb_array_elements_text(agent_sessions.document_ids) ' \
          'AS document_usage(document_id)'
        )
        .joins(
          'INNER JOIN captain_documents AS usage_documents ' \
          'ON usage_documents.id = document_usage.document_id::bigint ' \
          'AND usage_documents.assistant_id = agent_sessions.assistant_id'
        )
    end
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

  def account = document.account

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
           .where(assistant_id: document.assistant_id, subject_type: 'Conversation')
           .where('agent_sessions.document_ids @> ?', [document.id].to_json)
  end

  def record_serializer(records)
    @record_serializer ||= V2::Reports::DrilldownRecordSerializer.new(account, 'document_usage', false, records)
  end

  def current_page = [params[:page].to_i, DEFAULT_PAGE].max

  def per_page
    requested_per_page = params[:per_page].to_i
    requested_per_page = DEFAULT_PER_PAGE if requested_per_page <= 0

    [requested_per_page, MAX_PER_PAGE].min
  end
end
