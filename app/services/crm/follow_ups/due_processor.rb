class Crm::FollowUps::DueProcessor
  def initialize(now: Time.current)
    @now = now
  end

  def perform
    Crm::FollowUp.due(@now).find_each { |follow_up| process(follow_up) }
  end

  private

  # One bad row must never abort the whole sweep: any failure while processing a
  # single follow_up is logged with context and swallowed so the remaining due
  # rows (across all accounts) still get processed.
  def process(follow_up)
    follow_up.with_lock do
      next unless follow_up.pending? && follow_up.due_at <= @now

      dispatch(follow_up)
    end
  rescue StandardError => e
    log_processing_error(follow_up, e)
  end

  def dispatch(follow_up)
    if follow_up.auto_send_message? && ai_followup?(follow_up)
      process_ai_followup(follow_up)
    elsif follow_up.auto_send_message? && ai_callback?(follow_up)
      process_ai_callback(follow_up)
    elsif follow_up.auto_send_message?
      process_auto_send(follow_up)
    else
      process_overdue(follow_up)
    end
  end

  def log_processing_error(follow_up, error)
    Rails.logger.error(
      "[crm][follow_ups][due_processor] follow_up_id=#{follow_up.id} " \
      "error_class=#{error.class.name} message=#{error.message}"
    )
  end

  def ai_followup?(follow_up)
    follow_up.metadata.to_h['source'] == 'ai_followup'
  end

  def ai_callback?(follow_up)
    follow_up.metadata.to_h['source'] == 'ai_callback'
  end

  # AI kill-switch re-checked at execution (not just at scan/plan time): global
  # CRM_AI_ENABLED plus the pipeline's own auto-follow-up toggle.
  def ai_followup_enabled?(follow_up)
    Crm::Ai::Config.enabled? &&
      Crm::Ai::Config.auto_followup_settings(follow_up.card.pipeline)[:enabled]
  end

  def ai_callback_enabled?(follow_up)
    Crm::Ai::Config.enabled? &&
      Crm::Ai::Config.pipeline_callback_enabled?(follow_up.card.pipeline)
  end

  # Retorno por data (one-shot). O CallbackRunner ENVIA (free_form/template) ou devolve :fallback
  # quando não dá (sem template / encerramento / canal) — aí vira LEMBRETE pro humano (popup).
  def process_ai_callback(follow_up)
    # Kill-switch honored at EXECUTION: when AI is globally off or the pipeline
    # disabled callbacks, leave the row pending (do nothing) so it resumes if
    # re-enabled — never dispatch the runner (which would spend an AI call).
    return unless ai_callback_enabled?(follow_up)

    result = Crm::FollowUps::CallbackRunner.new(follow_up: follow_up, now: @now).perform

    case result.status
    when :sent
      follow_up.update!(status: :done, completed_at: @now)
      log_message_sent(follow_up, follow_up.conversation&.messages&.find_by(id: follow_up.metadata.to_h['sent_message_id']))
      finalize_follow_up(follow_up)
    when :fallback
      follow_up.update!(automation_mode: Crm::FollowUp.automation_modes[:reminder_only],
                        metadata: follow_up.metadata.merge('callback_fallback' => result.error.to_s))
      process_overdue(follow_up) # status overdue + reopen + notify popup + finalize
    when :failed
      follow_up.update!(due_at: result.retry_at, metadata: follow_up.metadata.merge('send_error' => result.error.to_s))
      log_message_failed(follow_up, result.error)
      finalize_follow_up(follow_up)
    end
  end

  # Isolated branch for AI auto-follow-up touches. Delegates the whole per-touch
  # decision (auto-stop gates, compose, window, cap, send, schedule next) to
  # Crm::FollowUps::AutoFollowupRunner, then maps its Result onto this follow_up's
  # final status exactly like process_auto_send does. process_auto_send /
  # process_overdue stay byte-for-byte unchanged for manual + stage automations.
  def process_ai_followup(follow_up)
    # Kill-switch honored at EXECUTION: when AI is globally off or the pipeline
    # auto-follow-up is disabled, leave the row pending (do nothing) so it
    # resumes if re-enabled — never dispatch the runner (which would spend an AI
    # call). The scan/planner flag alone never protected an already-scheduled row.
    return unless ai_followup_enabled?(follow_up)

    result = Crm::FollowUps::AutoFollowupRunner.new(follow_up: follow_up, now: @now).perform

    case result.status
    when :sent
      follow_up.update!(status: :done, completed_at: @now)
      log_message_sent(follow_up, follow_up.conversation&.messages&.find_by(id: follow_up.metadata.to_h['sent_message_id']))
    when :stopped, :skipped
      follow_up.update!(status: :done, completed_at: @now)
    when :rescheduled
      # Marketing-cap deferral: the runner pushed this SAME touch's due_at into the
      # future. Leave it pending so the next due sweep re-runs it once the cap clears.
    when :failed
      # TRANSIENT compose/send failure under the retry budget. Mirror :rescheduled:
      # keep the follow_up PENDING and bump due_at to the runner's retry_at so the
      # next due sweep re-runs the SAME touch (the `due` scope is pending-only, so an
      # :overdue touch would strand the cadence forever). The runner owns the bounded
      # retry counter; here we only re-arm the row.
      follow_up.update!(
        due_at: result.retry_at,
        metadata: follow_up.metadata.merge('send_error' => result.error.to_s)
      )
      log_message_failed(follow_up, result.error)
    when :failed_final
      # Retry budget exhausted. The runner already finalized the cadence state
      # (active:false, stopped_reason:'send_failed') and canceled siblings, so we just
      # close this touch out as done — letting the planner eventually re-evaluate the card.
      follow_up.update!(
        status: :done,
        completed_at: @now,
        metadata: follow_up.metadata.merge('send_error' => result.error.to_s)
      )
      log_message_failed(follow_up, result.error)
    end

    finalize_follow_up(follow_up)
  end

  def process_auto_send(follow_up)
    result = Crm::FollowUps::MessageSender.new(follow_up: follow_up).perform

    case result.status
    when :sent
      follow_up.update!(status: :done, completed_at: @now)
      log_message_sent(follow_up, result.message)
    when :skipped
      complete_already_sent_follow_up(follow_up)
    when :failed
      follow_up.update!(
        status: :overdue,
        metadata: follow_up.metadata.merge('send_error' => result.error.to_s)
      )
      log_message_failed(follow_up, result.error)
      notify_auto_send_failed(follow_up)
    end

    finalize_follow_up(follow_up)
  end

  def complete_already_sent_follow_up(follow_up)
    return if follow_up.metadata.to_h['sent_message_id'].blank?
    return if follow_up.done?

    follow_up.update!(status: :done, completed_at: @now)
  end

  def process_overdue(follow_up)
    follow_up.update!(status: :overdue)
    reopen_conversation(follow_up)
    log_overdue(follow_up)
    notify_reminder_due(follow_up)
    finalize_follow_up(follow_up)
  end

  def notify_reminder_due(follow_up)
    Crm::FollowUps::Broadcaster.broadcast_due(follow_up)
    Crm::FollowUps::ReminderNotifier.new(follow_up).perform
  end

  def notify_auto_send_failed(follow_up)
    user = follow_up.assignee
    return if user.blank? || user.pubsub_token.blank?

    ActionCableBroadcastJob.perform_later(
      [user.pubsub_token],
      Events::Types::CRM_FOLLOW_UP_DUE,
      auto_send_failed_payload(follow_up)
    )
  end

  def auto_send_failed_payload(follow_up)
    card = follow_up.card
    {
      account_id: follow_up.account_id,
      id: follow_up.id,
      title: follow_up.title,
      automation_mode: follow_up.automation_mode,
      due_at: follow_up.due_at&.iso8601,
      card_id: card&.id,
      card: card.present? ? { id: card.id, title: card.title, pipeline_id: card.pipeline_id } : nil,
      assignee_id: follow_up.assignee_id,
      auto_send_failed: true
    }
  end

  def finalize_follow_up(follow_up)
    Crm::FollowUps::CardNextDueUpdater.update(follow_up.card)
    Crm::Cards::Broadcaster.broadcast(follow_up.card, Events::Types::CRM_CARD_UPDATED)
  end

  def reopen_conversation(follow_up)
    return unless follow_up.snooze_conversation?
    return if follow_up.conversation.blank?

    follow_up.conversation.open!
  end

  def log_overdue(follow_up)
    Crm::ActivityLogger.new(
      card: follow_up.card,
      actor: nil,
      event_type: 'follow_up_overdue',
      conversation: follow_up.conversation,
      payload: {
        follow_up_id: follow_up.id,
        automation_mode: follow_up.automation_mode,
        due_at: follow_up.due_at&.iso8601
      }
    ).perform
  end

  def log_message_sent(follow_up, message)
    Crm::ActivityLogger.new(
      card: follow_up.card,
      actor: nil,
      event_type: 'follow_up_message_sent',
      conversation: follow_up.conversation,
      payload: {
        follow_up_id: follow_up.id,
        message_id: message&.id,
        send_mode: follow_up.metadata.to_h['send_mode'],
        due_at: follow_up.due_at&.iso8601
      }
    ).perform
  end

  def log_message_failed(follow_up, error)
    Crm::ActivityLogger.new(
      card: follow_up.card,
      actor: nil,
      event_type: 'follow_up_message_failed',
      conversation: follow_up.conversation,
      payload: {
        follow_up_id: follow_up.id,
        error: error.to_s,
        due_at: follow_up.due_at&.iso8601
      }
    ).perform
  end
end
