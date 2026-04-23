# Produces payloads for the C-Level dashboard:
#   - `.live(account:)`: current agent status (online/idle/offline), last
#     action per agent and the hottest open conversations.
#   - `.for_agent(account:, slug:, since:)`: per-agent KPIs in the window.
#
# Everything is account-scoped. Label-based queries use `acts_as_taggable_on`
# (Conversation `label_list`).
# rubocop:disable Metrics/ClassLength -- aggregator coeso de KPIs por agente.
class Synapseos::AgentMetricsQuery
  ONLINE_WINDOW = 5.minutes
  IDLE_WINDOW   = 30.minutes
  HOT_WINDOW    = 24.hours
  HOT_LIMIT     = 20

  # ----- LIVE ------------------------------------------------------------

  def self.live(account:)
    new(account).live_payload
  end

  def self.for_agent(account:, slug:, since:)
    new(account).agent_payload(slug: slug, since: since)
  end

  def initialize(account)
    @account = account
  end

  def live_payload
    {
      agents: AgentResolver::SLUGS.map { |slug| agent_status(slug) },
      hot_conversations: hot_conversations
    }
  end

  def agent_status(slug)
    bot_ids = AgentResolver.bots_for_slug(@account, slug).pluck(:id)
    last_msg = latest_message_for(bot_ids)
    last_label_event = latest_label_event_for(slug)

    last_action_at, last_action = newest_action(last_msg, last_label_event)

    {
      slug: slug,
      display_name: AgentResolver.display_name(slug),
      status: status_from(last_action_at),
      last_action: last_action,
      last_action_at: last_action_at
    }
  end

  def hot_conversations
    @account.conversations
            .open
            .where('last_activity_at >= ?', HOT_WINDOW.ago)
            .order(last_activity_at: :desc)
            .limit(HOT_LIMIT)
            .includes(:contact, :assignee, :assignee_agent_bot)
            .map { |c| hot_conversation_payload(c) }
  end

  # ----- PER-AGENT KPIS --------------------------------------------------

  def agent_payload(slug:, since:)
    {
      slug: slug,
      display_name: AgentResolver.display_name(slug),
      since: since.iso8601,
      kpis: kpis_for(slug, since)
    }
  end

  private

  def kpis_for(slug, since)
    method = "#{slug}_kpis"
    return {} unless respond_to?(method, true)

    send(method, since)
  end

  INCOMING_MSG_EXISTS = 'EXISTS (SELECT 1 FROM messages ' \
                        'WHERE messages.conversation_id = conversations.id ' \
                        'AND messages.message_type = 0)'.freeze

  BOT_HANDOFF_EXISTS = 'EXISTS (SELECT 1 FROM messages ' \
                       'WHERE messages.conversation_id = conversations.id ' \
                       'AND messages.sender_type = ? AND messages.sender_id IN (?))'.freeze

  SPEED_TO_LEAD_SQL = 'AVG(EXTRACT(EPOCH FROM (first_reply_created_at - created_at)))'.freeze

  # Alice (BDR outbound): conversas iniciadas ativamente, com tag `outbound`.
  def alice_kpis(since)
    outbound = conversations_with_label('outbound', since)
    replied = outbound.where(INCOMING_MSG_EXISTS)
    qualified = outbound.tagged_with('lead_qualificado')

    {
      leads_frios_contactados: outbound.count,
      taxa_resposta: ratio(replied.count, outbound.count),
      leads_convertidos: qualified.count
    }
  end

  # Iza (SDR inbound): conversas recebidas do cliente, sem tag outbound.
  def iza_kpis(since)
    iza_bot_ids = AgentResolver.bots_for_slug(@account, 'iza').pluck(:id)
    outbound_ids = conversations_with_label('outbound', since).pluck(:id)
    inbound = @account.conversations
                      .where('conversations.created_at >= ?', since)
                      .where.not(id: outbound_ids)
    speed = inbound.where.not(first_reply_created_at: nil).pick(Arel.sql(SPEED_TO_LEAD_SQL))
    qualified = inbound.tagged_with('lead_qualificado')
    handoffs = inbound.where.not(assignee_id: nil)
                      .where(BOT_HANDOFF_EXISTS, 'AgentBot', iza_bot_ids.presence || [0])

    {
      leads_inbound_recepcionados: inbound.count,
      speed_to_lead_seconds: speed&.to_f&.round,
      taxa_qualificacao: ratio(qualified.count, inbound.count),
      handoffs: handoffs.count
    }
  end

  def otto_kpis(since)
    bot_ids = AgentResolver.bots_for_slug(@account, 'otto').pluck(:id)
    {
      interacoes_crm: conversations_with_label('crm_updated', since).count,
      alertas_sla: private_notes_from(bot_ids, since).count,
      resgates: conversations_with_label('rescue_transbordo', since).count
    }
  end

  def luis_kpis(since)
    bot_ids = AgentResolver.bots_for_slug(@account, 'luis').pluck(:id)
    { assistencias_tecnicas: private_notes_from(bot_ids, since).count }
  end

  def fernanda_kpis(since)
    reactivated = conversations_with_label('resgatado_fernanda', since)
    pipeline_cents = deal_amount_cents_for_conversations(reactivated)

    {
      leads_reativados: reactivated.count,
      pipeline_resgatado_cents: pipeline_cents
    }
  end

  def angela_kpis(since)
    revisao = conversations_with_label('farming_revisao', since).count
    cross = conversations_with_label('farming_crosssell', since).count

    {
      agendamentos: crm_events_scope(since).where(event_type: 'appointment').count,
      taxa_crosssell: ratio(cross, revisao)
    }
  end

  def vitor_kpis(since)
    recovered = conversations_with_label('inadimplencia_recuperada', since)

    {
      acordos_fechados: crm_events_scope(since).where(event_type: 'pix_sent').count,
      valor_recuperado_cents: deal_amount_cents_for_conversations(recovered)
    }
  end

  # ----- helpers ---------------------------------------------------------

  def conversations_with_label(label, since)
    @account.conversations
            .where('conversations.created_at >= ?', since)
            .tagged_with(label)
  end

  def private_notes_from(bot_ids, since)
    return Message.none if bot_ids.empty?

    Message.where(account_id: @account.id,
                  message_type: :outgoing,
                  private: true,
                  sender_type: 'AgentBot',
                  sender_id: bot_ids)
           .where('created_at >= ?', since)
  end

  def crm_events_scope(since)
    ::Synapseos::CrmEvent.where(account_id: @account.id).where('created_at >= ?', since)
  end

  def deal_amount_cents_for_conversations(conversation_scope)
    conversation_ids = conversation_scope.pluck(:id)
    return 0 if conversation_ids.empty?

    lead_ids = ::Synapseos::Lead.where(account_id: @account.id, conversation_id: conversation_ids).pluck(:id)
    return 0 if lead_ids.empty?

    total = ::Synapseos::Deal.where(account_id: @account.id, lead_id: lead_ids).sum(:amount).to_d
    (total * 100).to_i
  end

  def ratio(numerator, denominator)
    return nil if denominator.to_i.zero?

    (numerator.to_f / denominator).round(4)
  end

  # ----- live helpers ----------------------------------------------------

  def latest_message_for(bot_ids)
    return nil if bot_ids.empty?

    Message.where(account_id: @account.id, sender_type: 'AgentBot', sender_id: bot_ids)
           .order(created_at: :desc)
           .first
  end

  def latest_label_event_for(slug)
    labels = label_emitters_for(slug)
    return nil if labels.empty?

    Message.joins(:conversation)
           .where(account_id: @account.id, message_type: :activity)
           .where('messages.content ILIKE ANY (ARRAY[?])', labels.map { |l| "%#{l}%" })
           .order(created_at: :desc)
           .first
  end

  # Labels each agent is responsible for emitting (per tags_contract.md).
  def label_emitters_for(slug)
    {
      'alice' => %w[outbound lead_qualificado],
      'iza' => %w[lead_novo_recepcionado lead_qualificado],
      'otto' => %w[crm_updated sla_alert rescue_transbordo],
      'luis' => %w[assistencia_tecnica],
      'fernanda' => %w[resgatado_fernanda],
      'angela' => %w[farming_revisao farming_crosssell],
      'vitor' => %w[inadimplencia_contato inadimplencia_recuperada]
    }[slug.to_s] || []
  end

  def newest_action(last_msg, last_label_event)
    candidates = []
    candidates << [last_msg.created_at, "Respondendo a ##{last_msg.conversation_id}"] if last_msg
    candidates << [last_label_event.created_at, "Marcou label em ##{last_label_event.conversation_id}"] if last_label_event
    return [nil, nil] if candidates.empty?

    candidates.max_by(&:first)
  end

  def status_from(timestamp)
    return 'offline' if timestamp.nil?
    return 'online' if timestamp >= ONLINE_WINDOW.ago
    return 'idle' if timestamp >= IDLE_WINDOW.ago

    'offline'
  end

  def hot_conversation_payload(conversation)
    assignee_name, assignee_type = assignee_info(conversation)
    status_label = conversation.cached_label_list_array.first
    time_in_stage = (Time.current - conversation.last_activity_at).to_i

    {
      id: conversation.display_id,
      contact_name: conversation.contact&.name,
      assignee_name: assignee_name,
      assignee_type: assignee_type,
      status_label: status_label,
      time_in_stage_seconds: time_in_stage
    }
  end

  def assignee_info(conversation)
    if conversation.assignee_agent_bot_id.present?
      bot = conversation.assignee_agent_bot
      [bot&.name, 'AgentBot']
    elsif conversation.assignee_id.present?
      [conversation.assignee&.name, 'User']
    else
      [nil, nil]
    end
  end
end
# rubocop:enable Metrics/ClassLength
