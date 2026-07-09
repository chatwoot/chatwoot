module Crm
  module FollowUps
    # Per-touch executor for an AI auto-follow-up cadence. Invoked by DueProcessor
    # (inside follow_up.with_lock) ONLY for follow-ups whose metadata.source ==
    # 'ai_followup'. Never touches manual / reminder / stage-automation follow-ups.
    #
    # Each due time it: (1) re-checks the hard auto-stop gates (including the
    # per-card "spent" budget) and cancels the cadence if any fires; (2) decides the
    # send mode from the messaging window — INSIDE 24h => :free_form (the AI writes a
    # natural PT-BR body), OUTSIDE 24h => :choose_template (the AI picks the best
    # APPROVED template from Crm::FollowUps::TemplateCandidates and fills its vars);
    # (3) composes via Crm::Ai::FollowUpComposer (the single brain: should_send +
    # closure detection + confidence), and applies the single gate; (4) enforces the
    # marketing-template frequency cap (1/24h/contact) by rescheduling the SAME touch
    # without consuming it; (5) writes the follow_up.metadata so the EXISTING
    # Crm::FollowUps::MessageSender does the right thing (session body vs chosen
    # template + native template vars); (6) sends via MessageSender (reusing the
    # entire session-vs-template path — no duplicated sending); and (7) on success
    # schedules touch+1 (quiet-hours-shifted) or completes the cadence at
    # max_touches. EVERY terminal outcome marks the card "spent" so the planner never
    # auto-replans it — only a manual reset re-arms a new cycle.
    #
    # Returns a Result; DueProcessor maps it onto the follow_up's final status and
    # calls finalize_follow_up. Idempotent: MessageSender skips when a
    # sent_message_id already exists, and the with_lock around #perform serializes
    # concurrent due-sweeps.
    class AutoFollowupRunner
      # :sent        -> message delivered, follow_up should be marked done
      # :stopped     -> a hard auto-stop fired, cadence canceled, follow_up done
      # :skipped     -> terminal no-send this cycle (no open loop / low confidence);
      #                 follow_up done
      # :rescheduled -> this SAME touch was deferred (marketing cap); follow_up MUST
      #                 stay pending so the next due sweep re-runs it
      # :failed      -> TRANSIENT delivery/compose failure; follow_up MUST stay
      #                 pending with a bumped due_at (carries retry_at) so the next
      #                 due sweep re-runs the SAME touch
      # :failed_final-> retry budget exhausted; runner already finalized the cadence
      #                 (state inactive + siblings canceled); follow_up should be
      #                 marked done so the planner can eventually re-evaluate the card
      Result = Struct.new(:status, :follow_up, :error, :retry_at, keyword_init: true) do
        def self.sent(follow_up)
          new(status: :sent, follow_up: follow_up)
        end

        def self.stopped(follow_up)
          new(status: :stopped, follow_up: follow_up)
        end

        def self.skipped(follow_up)
          new(status: :skipped, follow_up: follow_up)
        end

        def self.rescheduled(follow_up)
          new(status: :rescheduled, follow_up: follow_up)
        end

        def self.failed(follow_up, error, retry_at)
          new(status: :failed, follow_up: follow_up, error: error, retry_at: retry_at)
        end

        def self.failed_final(follow_up, error)
          new(status: :failed_final, follow_up: follow_up, error: error)
        end
      end

      MARKETING_CAP_WINDOW = 24.hours
      # A transient compose/send failure retries the SAME touch after this backoff
      # instead of stranding the cadence overdue.
      RETRY_BACKOFF = 45.minutes
      # After this many CONSECUTIVE failures the cadence is finalized rather than
      # retried forever.
      MAX_RETRIES = 3

      def initialize(follow_up:, now: Time.current)
        @follow_up = follow_up
        @now = now
        @card = follow_up.card
      end

      def perform
        stop_reason = auto_stop_reason
        return stop_cadence(stop_reason) if stop_reason.present?

        @send_mode = messaging_window.can_send_session_message? ? :free_form : :choose_template
        @candidates = @send_mode == :choose_template ? template_candidates : []
        composition = compose

        # Single gate. Closure/satisfaction => stop the whole cadence; everything
        # else that fails the gate is a skip-safe no-send (still terminal => spent).
        return stop_closure if closure?(composition)
        return skip(skip_reason(composition)) unless composable?(composition)

        prepare_send_metadata(composition)
        return reschedule_for_cap if capped?

        send_result = Crm::FollowUps::MessageSender.new(follow_up: @follow_up).perform
        handle_send_result(send_result)
      rescue Crm::Ai::ResponsesClient::Error, JSON::ParserError => e
        # Compose failure is not a delivery failure: keep the cadence intact and
        # let the next due sweep retry. Routed through fail_touch so it shares the
        # same bounded-retry / finalize logic as a send failure.
        fail_touch(e.message)
      end

      private

      # ---- (a) auto-stop re-checks --------------------------------------------

      # Returns a stopped_reason string when the cadence must hard-stop now, else nil.
      def auto_stop_reason
        return 'spent' if state['spent']
        return 'won_lost' if @card.won? || @card.lost? || @card.archived?
        return 'opt_out' if state['opted_out']
        return 'replied' if customer_replied_since_scheduling?

        nil
      end

      # A newer inbound message than the last touch we sent (or, before the first
      # send, than when this follow-up was created) means the customer re-engaged.
      def customer_replied_since_scheduling?
        conversation = @follow_up.conversation
        return false if conversation.blank?

        last_incoming = conversation.messages.incoming.reorder(id: :desc).first
        return false if last_incoming.blank?

        baseline = reply_baseline_at
        return false if baseline.blank?

        last_incoming.created_at > baseline
      end

      def reply_baseline_at
        last_sent = state['last_sent_at'].presence
        (last_sent && parse_time(last_sent)) || @follow_up.created_at
      end

      # ---- (a)/(c) compose via the AI brain + single gate ----------------------

      # @send_mode is decided in #perform (free_form inside 24h, choose_template
      # outside) so the composer gets the right mode + candidate list.
      def compose
        credential = credential_resolver.resolve
        # Fail closed: a missing OpenAI credential becomes a rescued transient
        # (routed through fail_touch) instead of a NoMethodError inside
        # ResponsesClient (@credential[:api_key]) that would abort the sweep.
        raise Crm::Ai::ResponsesClient::Error, 'missing_ai_credential' if credential.blank?

        client = Crm::Ai::ResponsesClient.new(
          credential: credential,
          feature: 'follow_up', account: @card.account, pipeline: @card.pipeline
        )
        context = Crm::Ai::ContextBuilder.new(card: @card).perform

        Crm::Ai::FollowUpComposer.new(
          card: @card,
          client: client,
          context: context,
          mode: @send_mode,
          candidates: @candidates,
          tone_instructions: config['tone_instructions'].to_s
        ).perform
      end

      # The approved-template candidate set for this conversation inbox (native
      # MARKETING HSMs or Channel::Api campaign templates). Empty in free_form mode
      # and whenever the inbox has no eligible templates.
      def template_candidates
        Crm::FollowUps::TemplateCandidates.new(conversation: @follow_up.conversation).perform
      end

      # Closure/satisfaction detected by the brain forces a hard stop of the whole
      # cadence (distinct from a plain skip): "Não enviado: conversa encerrada".
      def closure?(composition)
        return false unless composition

        Crm::Ai::Config::BOOLEAN.cast(composition['closure_detected'])
      end

      # Single gate: the AI must want to send AND be confident enough. In
      # choose_template mode it must ALSO have picked a resolvable candidate.
      def composable?(composition)
        return false unless composition
        return false unless Crm::Ai::Config::BOOLEAN.cast(composition['should_send'])
        return false if composition['confidence'].to_f < Crm::Ai::Config::FOLLOWUP_MIN_CONFIDENCE
        return resolved_candidate(composition).present? if @send_mode == :choose_template

        true
      end

      # Distinguishes the terminal skip reason for the drawer/timeline. closure is
      # handled separately (stop_closure); here we only reach a non-closure skip.
      def skip_reason(composition)
        return 'no_template' if @send_mode == :choose_template && resolved_candidate(composition).blank?

        'no_open_loop'
      end

      # ---- (b)+(d) metadata for MessageSender ----------------------------------

      # Writes follow_up.metadata so the EXISTING MessageSender takes the branch we
      # already decided in @send_mode (it independently re-checks the window at send
      # time, and our mode mirrors that same MessagingWindow check).
      def prepare_send_metadata(composition)
        metadata = base_metadata
        if @send_mode == :free_form
          metadata['message_body'] = composition['message_body'].to_s.strip
          metadata.delete('whatsapp_api_message_template_id')
          metadata.delete('template_name')
          metadata.delete('template_language')
          metadata.delete('template_processed_params')
        else
          apply_template_metadata(metadata, composition)
        end

        @follow_up.update!(metadata: metadata)
      end

      # The AI returns chosen_template.index; we resolve the actual candidate from
      # our own list (authoritative) and ignore any name/id/language drift.
      def apply_template_metadata(metadata, composition)
        candidate = resolved_candidate(composition)

        # Keep a generic body so AutoSendValidator's message_body check stays
        # satisfied; MessageSender ignores it for Api and uses it only as the
        # optional native body.
        metadata['message_body'] = composition['message_body'].to_s.strip.presence || metadata['message_body']
        # Persist the chosen template's Meta category so the 24h frequency cap can
        # target MARKETING only (Meta's 131049 cap is marketing-scoped). Api campaign
        # templates carry no category (nil) and are therefore never capped.
        metadata['template_category'] = candidate[:category].to_s.downcase.presence
        assign_template_channel_metadata(metadata, candidate, composition)
      end

      # Writes the channel-specific keys MessageSender needs (Api template id vs native
      # name/language/params), clearing the other channel's stale keys.
      def assign_template_channel_metadata(metadata, candidate, composition)
        if candidate[:kind].to_s == 'api'
          metadata['whatsapp_api_message_template_id'] = candidate[:id]
          metadata.delete('template_name')
          metadata.delete('template_language')
          # Channel::Api TemplateRenderer only substitutes contact name — positional
          # AI vars are unsupported there, so we never inject template_processed_params.
          metadata.delete('template_processed_params')
        else
          metadata['template_name'] = candidate[:name].to_s
          metadata['template_language'] = candidate[:language].presence || 'pt_BR'
          metadata['template_processed_params'] = stringify_template_variables(composition['template_variables'])
          metadata.delete('whatsapp_api_message_template_id')
        end
      end

      # Resolve (and memoize) the candidate the AI picked by index. Returns nil when
      # the index is out of range / the AI declined (index -1) — that drives the
      # 'no_template' skip and the composable? gate.
      def resolved_candidate(composition)
        return @resolved_candidate if defined?(@resolved_candidate)

        index = composition.dig('chosen_template', 'index')
        @resolved_candidate =
          if index.is_a?(Integer) && index >= 0
            @candidates[index]
          end
      end

      # Marketing-cap: at most one MARKETING reengagement template per CONTACT per
      # 24h (Meta's 131049 cap is marketing-scoped, per-recipient). Only a marketing
      # template send is capped — free session messages AND utility templates are
      # uncapped. Scoped to the contact (not just this card): a contact can own
      # multiple cards across pipelines, so we check the most recent ai_followup
      # MARKETING template send across ALL of the contact's cards.
      def capped?
        return false unless marketing_template_send?

        last_contact_template_at.present? &&
          last_contact_template_at > (@now - MARKETING_CAP_WINDOW)
      end

      # This touch is being delivered as a MARKETING template (category persisted by
      # apply_template_metadata). Utility/api templates return false so they escape
      # the cap entirely.
      def marketing_template_send?
        @send_mode == :choose_template && base_metadata['template_category'].to_s == 'marketing'
      end

      # Newest sent_at across this contact's AI follow-ups (auto-followup OR callback)
      # that were delivered as a MARKETING template. Meta's 131049 cap is per-recipient
      # regardless of which AI path sent it, so both sources count (mirrors
      # CallbackRunner). Falls back to this card's state when the follow-up carries no
      # contact_id.
      def last_contact_template_at
        return @last_contact_template_at if defined?(@last_contact_template_at)

        contact_id = @follow_up.contact_id || @card.contact_id
        @last_contact_template_at =
          if contact_id.present?
            sent_ats = @card.account.crm_follow_ups
                            .where(contact_id: contact_id)
                            .where("metadata ->> 'source' IN (?)", %w[ai_followup ai_callback])
                            .where("metadata ->> 'send_mode' = ?", 'template')
                            .where("metadata ->> 'template_category' = ?", 'marketing')
                            .pluck(Arel.sql("metadata ->> 'sent_at'"))
            sent_ats.filter_map { |value| parse_time(value) }.max
          else
            parse_time(state['last_marketing_template_sent_at'].presence)
          end
      end

      def reschedule_for_cap
        timezone = resolved_timezone
        next_due = compute_due(@now + MARKETING_CAP_WINDOW, timezone)
        @follow_up.update!(due_at: next_due)
        merge_state!('next_due_at' => next_due.iso8601)
        log_activity('ai_followup_capped', next_due_at: next_due.iso8601, touch: touch)
        Result.rescheduled(@follow_up)
      end

      # ---- (e) delegate sending + (f) outcomes --------------------------------

      def handle_send_result(send_result)
        case send_result.status
        when :sent
          on_sent(send_result.message)
        when :skipped
          # Already delivered (idempotent guard inside MessageSender). Treat as sent
          # for cadence purposes without re-logging a new send.
          Result.skipped(@follow_up)
        else
          on_failed(send_result.error)
        end
      end

      def on_sent(message)
        now_iso = @now.iso8601
        updates = { 'last_sent_at' => now_iso }
        # Only MARKETING template sends feed the 24h frequency-cap fallback marker
        # (contact-scoped query is authoritative; this covers follow-ups with no
        # contact_id). Utility/free_form sends are uncapped.
        updates['last_marketing_template_sent_at'] = now_iso if marketing_template_send?
        merge_state!(updates)
        record_touch!('sent')
        # A successful send clears any prior consecutive-failure streak so a later
        # touch starts its own fresh retry budget.
        reset_retries!
        log_activity('ai_followup_sent', touch: touch, send_mode: @send_mode.to_s, message_id: message&.id)

        schedule_next_touch
        Result.sent(@follow_up)
      end

      def on_failed(error)
        fail_touch(error)
      end

      # Bounded-retry handler shared by compose failures and send failures. Bumps a
      # consecutive-failure counter on the follow_up. Below MAX_RETRIES we keep the
      # SAME touch alive: DueProcessor stays pending and bumps due_at by the backoff
      # so the next sweep re-runs it (mirrors the :rescheduled cap deferral). At the
      # budget we finalize the cadence here (state inactive + siblings canceled) and
      # tell DueProcessor to mark the follow_up done so the planner can re-evaluate.
      def fail_touch(error)
        attempts = increment_retries!

        if attempts >= MAX_RETRIES
          cancel_pending_siblings
          merge_state!('active' => false, 'spent' => true, 'stopped_reason' => 'send_failed', 'next_due_at' => nil)
          record_touch!('skipped', 'send_failed')
          log_activity('ai_followup_failed', touch: touch, error: error.to_s, attempts: attempts, final: true)
          Result.failed_final(@follow_up, error)
        else
          retry_at = @now + RETRY_BACKOFF
          log_activity('ai_followup_failed', touch: touch, error: error.to_s, attempts: attempts, retry_at: retry_at.iso8601)
          Result.failed(@follow_up, error, retry_at)
        end
      end

      def schedule_next_touch
        if touch < max_touches
          next_touch = touch + 1
          timezone = resolved_timezone
          due_at = compute_due(last_inbound_at + interval_hours(next_touch).hours, timezone)
          Crm::FollowUps::AutoFollowupTouchBuilder.new(card: @card, touch: next_touch, due_at: due_at, timezone: timezone).perform
          merge_state!('active' => true, 'touch' => next_touch, 'next_due_at' => due_at.iso8601)
        else
          # (3) cadence reached its budget — mark the card spent so the planner
          # never auto-replans it (only a manual reset re-arms a new cycle).
          merge_state!('active' => false, 'spent' => true, 'stopped_reason' => 'max_touches', 'next_due_at' => nil)
          log_activity('ai_followup_completed', touch: touch)
        end
      end

      # ---- stop / skip helpers -------------------------------------------------

      # Hard auto-stop (won/lost/archived, opt-out, reply, spent). Terminal => spent.
      def stop_cadence(reason)
        cancel_pending_siblings
        merge_state!('active' => false, 'spent' => true, 'stopped_reason' => reason, 'next_due_at' => nil)
        log_activity('ai_followup_stopped', reason: reason, touch: touch)
        Result.stopped(@follow_up)
      end

      # Closure/satisfaction detected by the brain: stop the whole cadence with a
      # distinct reason so the drawer shows "Não enviado: conversa encerrada".
      def stop_closure
        cancel_pending_siblings
        merge_state!('active' => false, 'spent' => true, 'stopped_reason' => 'conversation_closed', 'next_due_at' => nil)
        record_touch!('skipped', 'conversation_closed')
        log_activity('ai_followup_stopped', reason: 'conversation_closed', touch: touch)
        Result.skipped(@follow_up)
      end

      # Skip-safe no-send (no open loop / low confidence / no suitable template).
      # Terminal => mark spent so the planner does not immediately re-arm.
      def skip(reason)
        cancel_pending_siblings
        merge_state!('active' => false, 'spent' => true, 'stopped_reason' => reason, 'next_due_at' => nil)
        record_touch!('skipped', reason)
        log_activity('ai_followup_stopped', reason: reason, touch: touch)
        Result.skipped(@follow_up)
      end

      # Cancel every other still-pending ai_followup touch on this card so a hard
      # stop kills the whole cadence, not just the current touch.
      def cancel_pending_siblings
        @card.follow_ups.active.where.not(id: @follow_up.id).find_each do |sibling|
          next unless sibling.metadata.to_h['source'] == 'ai_followup'

          sibling.update!(status: :canceled)
        end
      end

      # ---- metadata / state plumbing ------------------------------------------

      def base_metadata
        (@follow_up.metadata || {}).to_h.stringify_keys
      end

      # Consecutive-failure counter for THIS touch, stored on the follow_up metadata
      # so it survives across due-sweep retries of the same row.
      def increment_retries!
        metadata = base_metadata
        attempts = metadata['retries'].to_i + 1
        metadata['retries'] = attempts
        @follow_up.update!(metadata: metadata)
        attempts
      end

      def reset_retries!
        return if base_metadata['retries'].blank?

        metadata = base_metadata
        metadata.delete('retries')
        @follow_up.update!(metadata: metadata)
      end

      def state
        (@card.metadata || {}).fetch('ai', {}).to_h.fetch('auto_followup_state', {}).to_h
      end

      # Merge into card.metadata.ai.auto_followup_state without clobbering sibling
      # ai_* metadata (last_evaluated_at, value_source, etc.). Always (re)stamps
      # 'max_touches' so the drawer's 'N de M usados' denominator is correct even
      # for cadences seeded before max_touches was persisted by the planner.
      def merge_state!(changes)
        metadata = (@card.metadata || {}).deep_dup
        metadata['ai'] ||= {}
        metadata['ai']['auto_followup_state'] = state.merge('max_touches' => max_touches).merge(changes)
        @card.update!(metadata: metadata)
      end

      # (e) Append a per-touch record for the drawer timeline. Outcome is one of
      # 'sent'|'skipped'|'stopped'. For a free_form send mode is 'free_form'; for a
      # template send it carries the chosen template name; skips carry the reason.
      def record_touch!(outcome, reason = nil)
        entry = { 'touch' => touch, 'at' => @now.iso8601, 'outcome' => outcome }
        if outcome == 'sent'
          entry['mode'] = @send_mode == :free_form ? 'free_form' : 'template'
          entry['template_name'] = base_metadata['template_name'].presence if @send_mode == :choose_template
        end
        entry['reason'] = reason if reason.present?

        touches = Array(state['touches']).map(&:to_h)
        touches << entry
        merge_state!('touches' => touches)
      end

      # ---- config / channel helpers -------------------------------------------

      def config
        @config ||= Crm::Ai::Config.auto_followup_settings(@card.pipeline)
      end

      def touch
        @follow_up.metadata.to_h['touch'].to_i
      end

      def max_touches
        config['max_touches'].to_i
      end

      def interval_hours(touch_number)
        intervals = Array(config['intervals_hours'])
        # touch N is sent at intervals_hours[N-1]; default to the last interval.
        intervals[touch_number - 1].presence&.to_i || intervals.last.to_i
      end

      def messaging_window
        @messaging_window ||= Crm::FollowUps::MessagingWindow.new(@follow_up.conversation, at: @now)
      end

      def stringify_template_variables(variables)
        variables.to_h.transform_values(&:to_s)
      end

      def credential_resolver
        @credential_resolver ||= Crm::Ai::CredentialResolver.new(account: @card.account)
      end

      # ---- quiet-hours-aware due scheduling -----------------------------------

      # Clamp a candidate due time into the configured quiet-hours window
      # [start, end) in the contact's timezone (fallback account tz). If the
      # candidate falls before start, push to start the same day; if at/after end,
      # push to start the next day. No jitter in MVP.
      def compute_due(candidate, timezone = resolved_timezone)
        quiet = config['quiet_hours'].to_h
        start_hour = quiet['start'].presence&.to_i
        end_hour = quiet['end'].presence&.to_i
        return candidate if start_hour.blank? || end_hour.blank?

        local = candidate.in_time_zone(ActiveSupport::TimeZone[timezone])
        window_start = local.change(hour: start_hour, min: 0, sec: 0)
        window_end = local.change(hour: end_hour, min: 0, sec: 0)

        return window_start if local < window_start
        return (window_start + 1.day) if local >= window_end

        candidate
      end

      # MUST match AutoFollowupPlanner#resolved_timezone. Never blank (falls back
      # to the configurable default so the next touch always anchors to a real
      # local wall time).
      def resolved_timezone
        Crm::Timezone::Resolver.new(
          contact: @follow_up.contact || @card.contact, account: @card.account
        ).name_or_default
      end

      def last_inbound_at
        conversation = @follow_up.conversation
        last_incoming = conversation&.messages&.incoming&.reorder(id: :desc)&.first
        last_incoming&.created_at || @follow_up.created_at
      end

      def parse_time(value)
        Time.zone.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end

      def log_activity(event_type, payload = {})
        Crm::ActivityLogger.new(
          card: @card,
          actor: nil,
          event_type: event_type,
          conversation: @follow_up.conversation,
          payload: payload.merge(follow_up_id: @follow_up.id)
        ).perform
      end
    end
  end
end
