class Crm::Ai::HandoffEscalationJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Crm::Ai::Config.enabled?

    Crm::Pipeline.active.find_each do |pipeline|
      candidate_cards(pipeline).find_each do |card|
        settings = Crm::Ai::Config.handoff_settings(card.stage, card.pipeline)
        next unless actionable?(settings)

        handle_action(card, settings)
      end
    end
  end

  private

  def candidate_cards(pipeline)
    pipeline.cards.open
            .includes(:primary_conversation)
            .where("jsonb_typeof(metadata #> '{ai,handoffs}') = 'array'")
            .where("jsonb_array_length(metadata #> '{ai,handoffs}') > 0")
  end

  def actionable?(settings)
    return false unless settings[:enabled]
    return false unless settings[:handoff_mode] == 'r3_invite'
    return false unless settings[:pickup_threshold_seconds].to_i.positive?
    return settings[:escalation_user_id].present? if settings[:escalation_action] == 'escalate'

    settings[:escalation_action] == 'renotify'
  end

  def handle_action(card, settings)
    return escalate(card, settings) if settings[:escalation_action] == 'escalate'

    renotify(card, settings) if settings[:escalation_action] == 'renotify'
  end

  # Trava conversa→card (mesma ordem do drain) para serializar contra expiry/pickup/
  # executor, que travam o card e escrevem o MESMO JSONB. Sem o lock do card, o
  # stamp_escalation! rodava sobre metadata carregado fora de lock e podia perder o
  # write de um job concorrente (expiry marcando expired_at, p.ex.).
  def escalate(card, settings)
    conversation = card.primary_conversation
    return if conversation.blank?

    conversation.with_lock do
      card.with_lock { escalate_locked(card, conversation, settings) }
    end
  end

  def escalate_locked(card, conversation, _settings)
    settings = Crm::Ai::Config.handoff_settings(card.stage, card.pipeline)
    return unless locked_actionable?(card, settings, 'escalate')
    return if conversation.assignee_id.present?

    cycle = breached_open_cycle(card, settings[:pickup_threshold_seconds])
    return if cycle.blank?

    user = escalation_user(card, conversation, settings[:escalation_user_id])
    return unless escalation_target_ready?(card, settings, user)

    return unless assign_user(conversation, user)

    conversation.bot_handoff!
    stamp_escalation!(card, cycle, user.id)
    log_activity!(
      card,
      conversation,
      'ai_handoff_escalation',
      assignee_id: user.id,
      threshold_seconds: settings[:pickup_threshold_seconds].to_i
    )
  end

  # R3 renotify: re-notifica o MESMO agente convidado (cycle['invited_agent_id']) quando
  # o convite venceu o pickup_threshold e o escalation_action é 'renotify'. Não atribui,
  # não cala o bot, não fecha o ciclo. Carimba renotified_at/renotify_count SOB LOCK
  # (claim do slot) e notifica DEPOIS do lock — corrida concorrente relê fresh e cai no
  # renotify_due? (renotified_at recém-gravado), sem notificação dupla.
  def renotify(card, _settings)
    conversation = card.primary_conversation
    return if conversation.blank?

    result = nil
    conversation.with_lock do
      card.with_lock { result = renotify_locked(card, conversation) }
    end
    return if result.blank?

    notified = Crm::Ai::HandoffInviter.new(conversation: conversation, agent: result[:user]).perform
    log_renotify_activity!(card, conversation, result) if notified
  end

  def renotify_locked(card, conversation)
    settings = Crm::Ai::Config.handoff_settings(card.stage, card.pipeline)
    return unless locked_actionable?(card, settings, 'renotify')

    cycle = breached_open_cycle(card, settings[:pickup_threshold_seconds])
    return unless renotifiable_cycle?(cycle, settings)

    user = escalation_user(card, conversation, cycle['invited_agent_id'])
    return if user.blank?

    renotify_count = stamp_renotify!(card, cycle)
    return if renotify_count.blank?

    { user: user, renotify_count: renotify_count, threshold_seconds: settings[:pickup_threshold_seconds].to_i }
  end

  def renotifiable_cycle?(cycle, settings)
    cycle.present? && renotify_due?(cycle, settings) && renotify_cap_available?(cycle)
  end

  def renotify_due?(cycle, settings)
    last_touch = parse_time(cycle['renotified_at']) || parse_time(cycle['invited_at'])
    last_touch.present? && last_touch <= settings[:renotify_after_seconds].to_i.seconds.ago
  end

  def renotify_cap_available?(cycle)
    cycle['renotify_count'].to_i < Crm::Ai::Config::HANDOFF_RENOTIFY_MAX
  end

  def stamp_renotify!(card, cycle)
    renotify_count = cycle['renotify_count'].to_i + 1
    stamped = stamp_handoff_cycle!(
      card,
      cycle,
      'renotified_at' => Time.current.iso8601,
      'renotify_count' => renotify_count
    )
    stamped ? renotify_count : nil
  end

  def log_renotify_activity!(card, conversation, result)
    log_activity!(
      card,
      conversation,
      'ai_handoff_renotify',
      assignee_id: result[:user].id,
      renotify_count: result[:renotify_count],
      threshold_seconds: result[:threshold_seconds]
    )
  end

  def locked_actionable?(card, settings, action)
    card.open? && settings[:escalation_action] == action && actionable?(settings)
  end

  def breached_open_cycle(card, threshold_seconds)
    cycle = open_cycle(card)
    return if cycle.blank?

    invited_at = parse_time(cycle['invited_at'])
    invited_at.present? && invited_at <= threshold_seconds.to_i.seconds.ago ? cycle : nil
  end

  def assign_user(conversation, user)
    Conversations::AssignmentService.new(conversation: conversation, assignee_id: user.id).perform.present?
  end

  def escalation_user(card, conversation, user_id)
    user = card.account.users.find_by(id: user_id)
    return unless user.present? && inbox_member?(conversation, user)

    user
  end

  def inbox_member?(conversation, user)
    conversation.inbox&.members&.exists?(id: user.id)
  end

  # Escalar para supervisor OFFLINE cala a IA e deixa o cliente no vácuo (o
  # furo R2 do redesenho). Com prefer_online ligado, segura: a IA continua
  # atendendo e este job re-tenta a cada rodada até o supervisor ficar online.
  def escalation_target_ready?(card, settings, user)
    return false if user.blank?
    return true unless settings[:prefer_online]

    user_online?(card.account_id, user)
  end

  # Mesma fonte de presença do HandoffMemberSelector (Redis, janela curta).
  # Falha de leitura conta como offline: melhor re-tentar na próxima rodada
  # do que cravar num supervisor possivelmente ausente e calar a IA.
  def user_online?(account_id, user)
    OnlineStatusTracker.get_available_users(account_id)
                       .select { |_id, status| status == 'online' }
                       .keys.map(&:to_i)
                       .include?(user.id)
  rescue StandardError
    false
  end

  def open_cycle(card)
    cycles = (card.metadata || {}).dig('ai', 'handoffs')
    return unless cycles.is_a?(Array)

    cycles.reverse.find { |cycle| cycle['invited_at'].present? && cycle_open?(cycle) }
  end

  # Ciclo ainda aberto: sem nenhum estado terminal (pega, cancelamento por novo
  # convite, expiração por TTL ou escalação). Escalation só age em ciclo aberto.
  def cycle_open?(cycle)
    cycle['picked_up_at'].blank? &&
      cycle['canceled_at'].blank? &&
      cycle['expired_at'].blank? &&
      cycle['escalated_at'].blank?
  end

  def stamp_escalation!(card, cycle, user_id)
    stamp_handoff_cycle!(
      card,
      cycle,
      'escalated_at' => Time.current.iso8601,
      'escalated_to' => user_id
    )
  end

  def stamp_handoff_cycle!(card, cycle, fields)
    metadata = (card.metadata || {}).deep_dup
    ai = metadata['ai'] || {}
    cycles = ai['handoffs']
    return unless cycles.is_a?(Array)

    updated_cycles, matched = stamp_cycle(cycles, cycle, fields)
    return unless matched

    ai['handoffs'] = updated_cycles
    stamp_pointer!(ai, cycle, fields)
    metadata['ai'] = ai
    card.update!(metadata: metadata)
  end

  def stamp_cycle(cycles, cycle, fields)
    matched = false
    updated = cycles.map do |stored_cycle|
      if !matched && cycle_matches?(stored_cycle, cycle)
        matched = true
        stored_cycle.merge(fields)
      else
        stored_cycle
      end
    end
    [updated, matched]
  end

  def stamp_pointer!(ai_meta, cycle, fields)
    pointer = ai_meta['handoff']
    return unless pointer.is_a?(Hash) && cycle_matches?(pointer, cycle)

    ai_meta['handoff'] = pointer.merge(fields)
  end

  def cycle_matches?(stored_cycle, cycle)
    return stored_cycle['cycle_id'] == cycle['cycle_id'] if cycle['cycle_id'].present?

    stored_cycle['invited_at'] == cycle['invited_at']
  end

  def log_activity!(card, conversation, event_type, payload)
    Crm::ActivityLogger.new(
      card: card,
      actor: nil,
      event_type: event_type,
      conversation: conversation,
      payload: payload
    ).perform
  end

  def parse_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
