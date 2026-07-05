# Promotes a Click-to-WhatsApp (Meta CTWA) ad referral — delivered inside the first
# inbound message payload — into a first-class conversation attribute so it can drive
# Kanban badges and filtering. The rich attribution lives in
# `conversation.additional_attributes['campaign']`; the `meta_ctwa` account label is the
# UI-facing index (renders as the card chip and powers the existing Labels filter).
#
# Provider payloads differ (WhatsApp Cloud sends string keys, Twilio symbol keys and a
# `media_content_type` instead of `media_type`), so callers hand us the raw referral hash
# and this builder normalizes it into one shape.
module Ctwa::CampaignBuilder
  module_function

  LABEL = 'meta_ctwa'.freeze
  SOURCE = 'meta_ctwa'.freeze
  LABEL_COLOR = '#25D366'.freeze # WhatsApp green — distinguishes CTWA-sourced conversations

  # Builds the unified campaign attribution hash, or nil when the referral carries no
  # usable CTWA signal (a genuine ad referral always has a source id or click id).
  def build(referral)
    return if referral.blank?

    ref = referral.to_h.symbolize_keys
    return if ref[:source_id].blank? && ref[:ctwa_clid].blank?

    {
      'source' => SOURCE,
      'source_id' => ref[:source_id],
      'source_type' => ref[:source_type],
      'source_url' => ref[:source_url],
      'headline' => ref[:headline],
      'body' => ref[:body],
      'media_type' => ref[:media_type] || ref[:media_content_type],
      'ctwa_clid' => ref[:ctwa_clid]
    }.compact
  end

  # Attributes the conversation to the CTWA campaign. Idempotent: the first CTWA message
  # wins, later webhooks (or redeliveries) are a no-op once `campaign` is set.
  #
  # Webhooks are concurrent and retried, so the write is guarded by a row lock: the label is
  # ensured first (so `campaign` never lands without its badge), then the campaign is written
  # last inside the lock after a re-check, making "first wins" atomic and avoiding a lost
  # update on additional_attributes.
  def attribute!(conversation, referral)
    campaign = build(referral)
    return if campaign.blank?
    return if conversation.additional_attributes['campaign'].present?

    ensure_label(conversation.account)
    # reload discards the in-memory `display_id` set by the DB trigger, which `with_lock`
    # would otherwise reject as an unpersisted change.
    conversation.reload.with_lock do
      next if conversation.additional_attributes['campaign'].present?

      conversation.update!(
        additional_attributes: conversation.additional_attributes.merge('campaign' => campaign)
      )
      conversation.add_labels(LABEL)
    end
  end

  def ensure_label(account)
    account.labels.find_or_create_by!(title: LABEL) do |label|
      label.color = LABEL_COLOR
      label.show_on_sidebar = true
    end
  rescue ActiveRecord::RecordNotUnique
    # Two workers created the label concurrently; the retry now finds the winner's row.
    retry
  end
end
