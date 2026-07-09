module Crm
  module FollowUps
    # Scans ONE pipeline (auto_followup enabled) for cards whose primary
    # WhatsApp conversation has STALLED, and creates touch #1 of the AI
    # follow-up cadence for each newly-stalled, eligible card.
    #
    # Eligibility (all must hold):
    #   * card.open?                              (not won/lost/archived)
    #   * primary conversation present + WhatsApp-capable (MessagingWindow)
    #   * NO active ai_followup cadence already   (state.active != true AND no
    #     active Crm::FollowUp with metadata.source == 'ai_followup')
    #   * TWO-WAY conversation: >= 2 inbound (contact) messages AND >= 2 outbound
    #     (agent/AI, non-private) messages — don't chase a barely-started thread
    #   * last inbound message >= the FIRST configured send interval ago
    #
    # The "radar" (eligibility threshold) is DERIVED from the user's first send
    # interval (intervals_hours[0]) — never a fixed value — so a short cadence
    # (e.g. 1h/2h/3h) is picked up in time instead of waiting on a hardcoded
    # idle gate. Touch #1 due_at = last_inbound + intervals_hours[0], clamped
    # into quiet hours (already inside the 24h window when that interval < 24h).
    class AutoFollowupPlanner
      # Conversa precisa ter tido troca REAL dos dois lados antes de iniciar o follow-up.
      MIN_CONTACT_MESSAGES = 2
      MIN_AGENT_MESSAGES = 2

      def initialize(pipeline:, now: Time.current)
        @pipeline = pipeline
        @now = now
        @config = Crm::Ai::Config.auto_followup_settings(pipeline)
      end

      def perform
        return 0 unless @config[:enabled]

        planned = 0
        # Radar = the first send interval, so touch #1 is never scheduled in the
        # past relative to a separate, larger idle gate (the old bug). A card is
        # eligible exactly once it has been idle for the time the user picked for
        # the first follow-up.
        cutoff = first_interval_hours.hours.before(@now)

        @pipeline.cards.open.find_each do |card|
          planned += 1 if plan_for(card, cutoff)
        end
        planned
      end

      private

      def plan_for(card, cutoff)
        conversation = card.primary_conversation
        return false if conversation.blank?
        # SEM trava pelo agente de IA (decisão do PO): quem decide enviar o follow é o próprio cérebro
        # do follow-up (Crm::Ai::FollowUpComposer#should_send, que lê a conversa antes de enviar). Um
        # agente de IA no comando NÃO bloqueia mais a cadência — a guarda `native_agent_active?` foi
        # removida (contas só-IA, como a 6, PRECISAM de follow-up).
        return false unless Crm::FollowUps::MessagingWindow.new(conversation, at: @now).whatsapp_capable?
        return false if cadence_active?(card) || cadence_spent?(card)
        return false if pending_callback?(card)
        return false unless sufficient_two_way_exchange?(conversation)

        last_inbound = last_inbound_message(conversation)
        return false if last_inbound.blank?
        return false if last_inbound.created_at > cutoff

        create_first_touch(card, last_inbound).present?
      end

      # Só inicia se a conversa principal teve mão dupla real: >= 2 mensagens do cliente E >= 2 do
      # agente. "Agente" = mensagens outgoing (humano OU IA/bot); ignora notas privadas, eventos de
      # sistema (activity) e templates automáticos — só conta troca real com o cliente. Usa os scopes
      # do enum (WHERE message_type = 0/1), sem depender de como group(:message_type) chaveia.
      def sufficient_two_way_exchange?(conversation)
        non_private = conversation.messages.where(private: false)
        non_private.incoming.count >= MIN_CONTACT_MESSAGES &&
          non_private.outgoing.count >= MIN_AGENT_MESSAGES
      end

      # GUARDA: NÃO inicia a cadência genérica de auto-followup se o card tem um RETORNO POR DATA
      # (ai_callback) pendente com data futura — o cliente já disse QUANDO voltar; não perturbar antes.
      # Depois que o callback dispara (vira done/overdue), o card volta a ser elegível normalmente.
      def pending_callback?(card)
        card.follow_ups.active.any? do |follow_up|
          follow_up.metadata.to_h['source'] == 'ai_callback' &&
            follow_up.due_at.present? && follow_up.due_at > @now
        end
      end

      def cadence_active?(card)
        state = card.metadata.to_h.dig('ai', 'auto_followup_state') || {}
        return true if state['active'] == true

        card.follow_ups.active.any? do |follow_up|
          follow_up.metadata.to_h['source'] == 'ai_followup'
        end
      end

      # BUDGET PER CARD, ONCE: a card whose cadence has run to a terminal state
      # is marked spent by the runner. The planner must NEVER auto-re-arm a spent
      # card, even if the contact later replies and goes silent again. Only a
      # manual RESET (which clears spent) re-arms a new cycle.
      def cadence_spent?(card)
        card.metadata.to_h.dig('ai', 'auto_followup_state', 'spent') == true
      end

      def create_first_touch(card, last_inbound)
        timezone = resolved_timezone(card)
        due_at = compute_first_due(last_inbound.created_at, timezone)

        follow_up = Crm::FollowUps::AutoFollowupTouchBuilder.new(
          card: card,
          touch: 1,
          due_at: due_at,
          timezone: timezone
        ).perform

        write_state(card, due_at)
        Crm::FollowUps::CardNextDueUpdater.update(card)
        log_planned(card, follow_up, last_inbound)
        follow_up
      end

      # Touch #1 fires intervals_hours[0] after the last inbound — the SAME value
      # that gates eligibility — so once a card is picked up the send time is
      # "now or just past" and fires on the next quiet-hours slot, never late.
      def compute_first_due(last_inbound_at, timezone)
        target = last_inbound_at + first_interval_hours.hours
        target = @now if target < @now
        clamp_into_quiet_hours(target, timezone)
      end

      def clamp_into_quiet_hours(time, timezone)
        quiet = @config[:quiet_hours].to_h
        start_hour = quiet['start'].to_i
        end_hour = quiet['end'].to_i
        return time if start_hour >= end_hour

        zone = ActiveSupport::TimeZone[timezone]
        local = time.in_time_zone(zone)
        if local.hour < start_hour
          local.change(hour: start_hour, min: 0, sec: 0).utc
        elsif local.hour >= end_hour
          (local + 1.day).change(hour: start_hour, min: 0, sec: 0).utc
        else
          time
        end
      end

      # Resolves the cadence timezone (contact -> contact country -> account
      # reporting_timezone -> configurable default). MUST match
      # AutoFollowupRunner#resolved_timezone so touch #1 (planner) and touch #2+
      # (runner) clamp to the SAME local window. Never blank.
      def resolved_timezone(card)
        Crm::Timezone::Resolver.new(contact: card.contact, account: @pipeline.account).name_or_default
      end

      # Seed the full cadence-state shape the runner and the card drawer rely on:
      # 'spent' (budget-per-card gate), 'touches' (drawer mini-timeline) and
      # 'max_touches' (the 'N de M usados' denominator). No template is pre-seeded —
      # the AI chooses it at send time (see AutoFollowupTouchBuilder).
      def write_state(card, due_at)
        metadata = card.metadata.to_h.deep_dup
        metadata['ai'] ||= {}
        metadata['ai']['auto_followup_state'] = {
          'active' => true,
          'spent' => false,
          'touch' => 1,
          'max_touches' => @config[:max_touches].to_i,
          'touches' => [],
          'next_due_at' => due_at.utc.iso8601,
          'last_sent_at' => nil,
          'stopped_reason' => nil,
          'opted_out' => false,
          'last_marketing_template_sent_at' => nil
        }
        card.update!(metadata: metadata)
      end

      def log_planned(card, follow_up, last_inbound)
        Crm::ActivityLogger.new(
          card: card,
          actor: nil,
          event_type: 'ai_followup_planned',
          conversation: card.primary_conversation,
          payload: {
            follow_up_id: follow_up.id,
            touch: 1,
            due_at: follow_up.due_at&.utc&.iso8601,
            last_message_role: last_message_role(card.primary_conversation),
            last_inbound_at: last_inbound.created_at.utc.iso8601
          }
        ).perform
      end

      def last_inbound_message(conversation)
        conversation.messages.incoming.reorder(id: :desc).first
      end

      # 'customer' when the conversation's most recent non-activity message is
      # inbound (they asked, we went silent); 'agent' when it is outgoing/template
      # (we asked, they went silent). Drives the composer stall-type prompt.
      def last_message_role(conversation)
        last = conversation.messages
                           .where(message_type: [Message.message_types[:incoming],
                                                  Message.message_types[:outgoing],
                                                  Message.message_types[:template]])
                           .reorder(id: :desc)
                           .first
        return 'customer' if last.nil?

        last.incoming? ? 'customer' : 'agent'
      end

      # The first send interval drives BOTH the radar (eligibility) and touch #1's
      # due time. trigger_idle_hours is no longer read here (kept in config only
      # for backward-compatible payloads); the user controls a single time.
      def first_interval_hours
        intervals = Array(@config[:intervals_hours])
        intervals[0].to_i.positive? ? intervals[0].to_i : 20
      end
    end
  end
end
