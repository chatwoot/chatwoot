module Crm
  module Webhooks
    # Bridges Crm::Activity lifecycle events onto the native Events dispatcher so
    # WebhookListener can fan them out to account webhooks.
    #
    # Called from an after_commit hook on Crm::Activity (NOT from ActivityLogger,
    # which runs inside the mover/closer/creator transaction — see plan B2). The
    # caller passes IDS ONLY; the downstream listener reloads records by id.
    #
    # EVENT_MAP keys are the REAL event_type strings written by the CRM services
    # (verified: creator.rb 'create', mover.rb 'move', closer.rb 'won'/'lost'/'reopen',
    # cards_controller.rb 'archive'). Values are the dotted dispatcher constants.
    # This is an explicit allowlist: any event_type not listed (ai_*, follow_up_*,
    # conversation_sync, conversation_dedup_reuse, ...) is silently ignored for the
    # MVP (plan D3).
    class Emitter
      EVENT_MAP = {
        'create' => Events::Types::CRM_CARD_CREATED,
        'move' => Events::Types::CRM_CARD_MOVED,
        'won' => Events::Types::CRM_CARD_WON,
        'lost' => Events::Types::CRM_CARD_LOST,
        'reopen' => Events::Types::CRM_CARD_REOPENED,
        'archive' => Events::Types::CRM_CARD_ARCHIVED
      }.freeze

      # Dispatcher event -> pipeline.metadata['meta_sync']['events'] token consumed by
      # Crm::MetaCapiListener. Only these three lifecycle events feed the Meta CAPI sync.
      META_SYNC_EVENT_TOKENS = {
        Events::Types::CRM_CARD_WON => 'won',
        Events::Types::CRM_CARD_LOST => 'lost',
        Events::Types::CRM_CARD_MOVED => 'moved'
      }.freeze

      def initialize(account_id:, card_id:, activity_id:, event_type:, changed_attributes: nil)
        @account_id = account_id
        @card_id = card_id
        @activity_id = activity_id
        @event_type = event_type.to_s
        @changed_attributes = changed_attributes
      end

      def self.emit(...)
        new(...).perform
      end

      def perform
        event = EVENT_MAP[@event_type]
        return if event.blank?
        return unless any_account_webhook_subscribed?(event) || meta_sync_subscribed?(event) || google_sync_subscribed?(event)

        Rails.configuration.dispatcher.dispatch(
          event,
          Time.zone.now,
          account_id: @account_id,
          card_id: @card_id,
          activity_id: @activity_id,
          event: event,
          changed_attributes: @changed_attributes
        )
      end

      private

      def account
        return @account if defined?(@account)

        @account = Account.find_by(id: @account_id)
      end

      # Early-exit (plan R1): skip enqueuing EventDispatcherJob unless at least one
      # account webhook subscribes this event, to avoid flooding the queue on every
      # Crm::Activity write (AI auto-move / bulk move amplify this).
      def any_account_webhook_subscribed?(event)
        return false if account.blank?

        account.webhooks.account_type.any? { |webhook| webhook.subscriptions.to_a.include?(event) }
      end

      # The Meta CAPI listener has no account webhook, so the early-exit above would
      # silence it entirely. Dispatch also when any active pipeline opted into Meta
      # sync for this event (pipeline.metadata['meta_sync']: enabled + events[token]).
      def meta_sync_subscribed?(event)
        sync_subscribed?(event, 'meta_sync')
      end

      # Same rationale for the Google offline conversions listener: an account with
      # only google_sync enabled must still get the dispatch.
      def google_sync_subscribed?(event)
        sync_subscribed?(event, 'google_sync')
      end

      def sync_subscribed?(event, metadata_key)
        token = META_SYNC_EVENT_TOKENS[event]
        return false if token.blank? || account.blank?

        account.crm_pipelines.active.any? do |pipeline|
          sync = pipeline.metadata&.dig(metadata_key) || {}
          sync['enabled'] && sync.dig('events', token)
        end
      end
    end
  end
end
