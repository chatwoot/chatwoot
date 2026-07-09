# Idempotent CTWA revenue backfill: re-emits Meta CAPI events for cards that
# transitioned BEFORE the sync was enabled (or while it was misconfigured).
#
# Dry-run by DEFAULT: it never sends and never writes, only returns/logs a report
# of what WOULD be sent. Flip dry_run:false to actually enqueue Crm::MetaCapi::DispatchJob
# (tagged source:'backfill' on the ledger) for the same cards.
#
# For each card it reconstructs the SAME deterministic event_id the live path
# (DispatchJob#build_event_id) would have produced, by reusing the triggering
# activity's id. A ledger row already `accepted` for that event_id is skipped, so
# re-running the backfill never double-posts (true idempotency).
#
# Candidate events per card (mirrors Crm::MetaCapiListener's three transitions):
#   - RESULT axis: 'won'/'lost' when the card is closed (carries value_cents).
#   - STAGE axis:  'moved' for the CURRENT stage, only when that stage has a
#     funnel_stage_type configured.
# Both are gated by the pipeline's meta_sync config (enabled + event subscribed).
#
# SECURITY: this job never touches the Meta access token — DispatchJob resolves and
# posts it. Nothing token-shaped is ever logged here.
class Crm::MetaCapi::BackfillJob < ApplicationJob
  queue_as :low

  # Real-mode throttle so a large account doesn't flood the Graph API: pause after
  # each batch of enqueued dispatches. Dry-run never sleeps (it enqueues nothing).
  BATCH_SIZE = 100
  BATCH_SLEEP_SECONDS = 1
  MOVEMENT_ACTIVITY_TYPES = %w[move create].freeze

  def perform(account_id, dry_run: true)
    account = Account.find_by(id: account_id)
    report = build_report(account_id, dry_run)
    return finalize(report) if account.blank?

    enabled_pipelines(account).each { |pipeline| process_pipeline(pipeline, report) }
    finalize(report)
  end

  private

  def process_pipeline(pipeline, report)
    cards_scope(pipeline).find_each(batch_size: BATCH_SIZE) do |card|
      process_card(card, pipeline, report)
    end
  end

  def process_card(card, pipeline, report)
    ctwa_clid = Crm::MetaCapi::CtwaClidResolver.resolve(card)
    if ctwa_clid.blank?
      report[:skipped_no_clid] += 1
      return
    end

    candidate_events(card, pipeline).each { |capi_event, activity| process_event(card, capi_event, activity, report) }
  end

  def process_event(card, capi_event, activity, report)
    event_id = build_event_id(card, capi_event, activity)
    if already_sent?(event_id)
      report[:already_sent] += 1
      return
    end

    report[:would_send] += 1
    report[:by_event_type][capi_event] += 1
    enqueue_dispatch(card, capi_event, activity, report) unless report[:dry_run]
  end

  # Result axis first (won/lost), then the current-stage movement. Each event is a
  # [capi_event, activity] pair; the activity supplies the deterministic event_id.
  def candidate_events(card, pipeline)
    [result_event(card), movement_event(card)].compact.select do |capi_event, _activity|
      subscribed?(pipeline, capi_event)
    end
  end

  # card.status is the enum name ('won'/'lost'), which also matches the closer's
  # activity event_type and the CAPI event name — so no mapping is needed here.
  def result_event(card)
    return unless card.won? || card.lost?

    activity = latest_activity(card, [card.status])
    activity && [card.status, activity]
  end

  # Movement uses the CURRENT stage; only emit when that stage opted in with a
  # funnel_stage_type. The latest move/create activity anchors the event_id.
  def movement_event(card)
    return if Crm::MetaCapi::StageTypeResolver.resolve(card.stage).blank?

    activity = latest_activity(card, MOVEMENT_ACTIVITY_TYPES)
    activity && ['moved', activity]
  end

  def latest_activity(card, event_types)
    card.activities.where(event_type: event_types).order(created_at: :desc).first
  end

  # Mirrors Crm::MetaCapiListener#meta_sync_enabled?: the event must be subscribed
  # under the pipeline's meta_sync config for the backfill to consider it.
  def subscribed?(pipeline, capi_event)
    pipeline.metadata.dig('meta_sync', 'events', capi_event).present?
  end

  # Must stay identical to Crm::MetaCapi::DispatchJob#build_event_id so a live event
  # already sent for the same transition is recognised and skipped.
  def build_event_id(card, capi_event, activity)
    "crm-#{card.id}-#{capi_event}-#{activity.id}"
  end

  def already_sent?(event_id)
    Crm::MetaConversionEvent.accepted.exists?(event_id: event_id)
  end

  def enqueue_dispatch(card, capi_event, activity, report)
    Crm::MetaCapi::DispatchJob.perform_later(card.account_id, card.id, activity.id, capi_event, source: 'backfill')
    report[:enqueued] += 1
    throttle(report[:enqueued])
  end

  def throttle(enqueued)
    sleep(BATCH_SLEEP_SECONDS) if (enqueued % BATCH_SIZE).zero?
  end

  def enabled_pipelines(account)
    account.crm_pipelines.select { |pipeline| pipeline.metadata.dig('meta_sync', 'enabled').present? }
  end

  def cards_scope(pipeline)
    pipeline.cards.where.not(conversation_id: nil)
  end

  def build_report(account_id, dry_run)
    {
      account_id: account_id,
      dry_run: dry_run,
      would_send: 0,
      skipped_no_clid: 0,
      already_sent: 0,
      enqueued: 0,
      by_event_type: Hash.new(0)
    }
  end

  def finalize(report)
    Rails.logger.info(
      "Crm::MetaCapi::BackfillJob account=#{report[:account_id]} dry_run=#{report[:dry_run]} " \
      "would_send=#{report[:would_send]} skipped_no_clid=#{report[:skipped_no_clid]} " \
      "already_sent=#{report[:already_sent]} enqueued=#{report[:enqueued]} by_event_type=#{report[:by_event_type]}"
    )
    report
  end
end
