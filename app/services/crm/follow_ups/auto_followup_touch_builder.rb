module Crm
  module FollowUps
    # Creates ONE auto-send Crm::FollowUp representing a single touch of an AI
    # auto-follow-up cadence. Used by AutoFollowupPlanner (touch #1) and by
    # AutoFollowupRunner (touch+1). No template is pre-seeded: the AI chooses the
    # template (or writes a free-form body) at send time and the runner fills
    # metadata right before MessageSender. AutoSendValidator skips the create-time
    # template-fallback gate for ai_followup-sourced follow-ups.
    #
    # The follow-up is auto_send_message / message so it flows through the
    # EXISTING DueProcessor -> MessageSender path. metadata carries the
    # 'source' => 'ai_followup' marker (so DueProcessor branches to
    # AutoFollowupRunner and the Planner/Canceler can recognise the cadence)
    # plus the touch number. A placeholder message_body keeps AutoSendValidator
    # satisfied at create time; the runner overwrites it with the composed body.
    #
    # NOTE: metadata is built directly (NOT via MetadataSanitizer) because the
    # sanitizer whitelists only the send-time keys and would drop source/touch.
    class AutoFollowupTouchBuilder
      PLACEHOLDER_BODY = '...'.freeze

      def initialize(card:, touch:, due_at:, timezone: nil, template_metadata: {})
        @card = card
        @touch = touch.to_i
        @due_at = due_at
        @timezone = timezone
        @template_metadata = (template_metadata || {}).to_h.stringify_keys
      end

      def perform
        @card.account.crm_follow_ups.create!(
          card: @card,
          conversation: conversation,
          contact_id: contact_id,
          inbox_id: inbox_id,
          assignee: resolved_sender,
          created_by: resolved_sender,
          title: title,
          follow_up_type: :message,
          automation_mode: :auto_send_message,
          due_at: @due_at,
          timezone: timezone,
          metadata: metadata
        )
      end

      private

      def conversation
        @card.primary_conversation
      end

      # A single auto-send touch dies as 'send_failed' ('sender_required') when it
      # has no sender, so resolve one even for AI-only / unassigned cards: card
      # owner -> the linked conversation's human assignee -> account administrator.
      def resolved_sender
        @resolved_sender ||= @card.owner || conversation&.assignee || @card.account.administrators.first
      end

      def contact_id
        @card.contact_id || conversation&.contact_id
      end

      def inbox_id
        @card.inbox_id || conversation&.inbox_id
      end

      def title
        I18n.t('crm.follow_ups.auto_followup.title', touch: @touch, default: "AI follow-up #{@touch}")
      end

      def timezone
        @timezone.presence ||
          Crm::Timezone::Resolver.new(contact: @card.contact, account: @card.account).name_or_default
      end

      def metadata
        {
          'source' => 'ai_followup',
          'touch' => @touch,
          'message_body' => PLACEHOLDER_BODY
        }.merge(template_metadata)
      end

      # No template is pre-seeded: the AI chooses the template (or writes a
      # free-form body) at send time and the runner fills the metadata just before
      # MessageSender. AutoSendValidator skips the create-time template-fallback
      # gate for ai_followup-sourced follow-ups, so an empty metadata is valid.
      def template_metadata
        @template_metadata.presence || {}
      end
    end
  end
end
