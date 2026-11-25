# Searches replies that human agents sent in this account's other conversations. It uses the OpenSearch message index,
# or on self-hosted installations without one, the same bounded Postgres text match the dashboard search falls back to.
# The model controls only the search text. The account, the agent's access and the message filters come from the
# server, and every hit is checked again in Postgres before the model sees it.
class Captain::Tools::SearchPastRepliesService < RubyLLM::Tool
  prepend Captain::Tools::Instrumentation
  include Captain::Copilot::ConversationAccess

  MAX_SEARCHES = 3
  MAX_RESULTS = 5
  CANDIDATE_LIMIT = 25
  QUERY_LENGTH = (3..200)
  TEXT_LIMIT = 1_000
  SOURCES = %i[index database].freeze
  # Words of at least this length, at most this many, each matched against the trigram index on messages.content.
  MIN_WORD_LENGTH = 3
  MAX_DATABASE_WORDS = 4

  description 'Search replies that agents of this business sent to customers in other conversations'
  parameter :query, description: 'Words describing the customer question to look for in past agent replies', required: true

  # The only call to the search index, kept apart so specs can run without OpenSearch. Any word may match, ranked by
  # relevance, because the model writes whole-sentence queries that rarely share every word with one reply.
  def self.candidate_message_ids(query, where:)
    Message.search(query, fields: %w[content], where: where, operator: 'or', limit: CANDIDATE_LIMIT, load: false).map { |hit| hit.id.to_i }
  end

  def initialize(account:, user:, conversation:, source: :index)
    raise ArgumentError, "Unknown past reply source: #{source}" unless SOURCES.include?(source)

    @account = account
    @user = user
    @conversation = conversation
    @source = source
    @searches = 0
    super()
  end

  def name
    'search_past_replies'
  end

  def execute(query: nil, **)
    return 'The query must be text between 3 and 200 characters.' unless query.is_a?(String) && QUERY_LENGTH.cover?(query.strip.length)
    return 'The search limit for this draft has been reached.' if @searches >= MAX_SEARCHES

    @searches += 1
    replies = past_replies(query.strip)
    log_search(replies.size)
    return 'No past replies found for the given query' if replies.empty?

    replies.map { |reply| format_reply(reply) }.join
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    'Past replies are unavailable right now.'
  end

  private

  def past_replies(query)
    candidate_ids = @source == :index ? self.class.candidate_message_ids(query, where: index_filters) : database_candidate_ids(query)
    return [] if candidate_ids.empty?

    replies = verified_replies(candidate_ids).index_by(&:id)
    candidate_ids.filter_map { |id| replies[id] }.first(MAX_RESULTS)
  end

  # The same search window as the database path. Like the dashboard search, an agent who is not an administrator is
  # limited to their own inboxes before the top candidates are taken, so other inboxes cannot crowd out their results.
  def index_filters
    filters = {
      account_id: @account.id,
      message_type: 'outgoing',
      private: false,
      sender_type: 'User',
      conversation_id: { not: @conversation.id },
      created_at: { gte: Limits.search_time_range_limit_days.days.ago }
    }
    return filters if administrator?

    filters.merge(inbox_id: @user.inboxes.where(account_id: @account.id).pluck(:id))
  end

  def administrator?
    @account.account_users.find_by(user_id: @user.id)&.administrator?
  end

  # Like the dashboard's SQL message search: this account, the search window, newest first, every word present. Only
  # conversations the agent can open are searched, so replies they cannot read do not take the candidate places.
  def database_candidate_ids(query)
    words = query.scan(/[[:alnum:]]+/).select { |word| word.length >= MIN_WORD_LENGTH }.uniq.first(MAX_DATABASE_WORDS)
    return [] if words.empty?

    content = Message.arel_table[:content]
    relation = words.reduce(recent_agent_replies) { |scope, word| scope.where(content.matches("%#{Message.sanitize_sql_like(word)}%")) }
    relation.where(conversation_id: allowed_conversations.select(:id)).reorder(created_at: :desc).limit(CANDIDATE_LIMIT).pluck(:id)
  end

  def recent_agent_replies
    @account.messages.where(message_type: :outgoing, private: false, sender_type: 'User')
            .where(Message.arel_table[:created_at].gteq(Limits.search_time_range_limit_days.days.ago))
            .where.not(conversation_id: @conversation.id)
  end

  def allowed_conversations
    accessible_conversations(account: @account, user: @user).where.not(id: @conversation.id)
  end

  # The index can lag behind the database, so each hit is checked against the same rules plus the agent's access.
  def verified_replies(candidate_ids)
    Message.where(id: candidate_ids, account_id: @account.id, private: false, message_type: :outgoing, sender_type: 'User')
           .where(conversation_id: allowed_conversations.select(:id))
           .includes(:conversation)
  end

  def format_reply(reply)
    question = answered_message(reply)
    text = "\n<past_reply conversation=\"#{reply.conversation.display_id}\" date=\"#{reply.created_at.to_date.iso8601}\">\n"
    text += "Customer: #{question.content_for_llm.to_s.truncate(TEXT_LIMIT)}\n" if question
    text + "Agent reply: #{reply.content_for_llm.to_s.truncate(TEXT_LIMIT)}\n</past_reply>\n"
  end

  def answered_message(reply)
    reply.conversation.messages.where(message_type: :incoming, private: false)
         .where(created_at: ...reply.created_at).reorder(created_at: :desc).first
  end

  def log_search(result_count)
    Rails.logger.info(
      "[CAPTAIN][SearchPastReplies] account=#{@account.id} conversation=#{@conversation.display_id} " \
      "source=#{@source} search=#{@searches} results=#{result_count}"
    )
  end
end
