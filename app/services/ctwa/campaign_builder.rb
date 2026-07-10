require 'digest/sha1'
require 'uri'

# Promotes Click-to-WhatsApp (Meta CTWA) referrals and tracked-link bridge
# attribution into first-class conversation attributes so they can drive the Kanban
# campaign pill and the campaign filters. Multi-touch: every attribution touch lands
# in `conversation.additional_attributes` across three keys:
#
# * `campaign` — origin hash (first touch, full shape including `body`).
# * `campaign_touches` — chronological append-only list of slim touches (no `body`,
#   which would bloat webhook/conversation payloads with ad copy on every click).
# * `campaign_source_ids` — flat mirror of unique source ids powering the filters.
#
# Provider payloads differ (WhatsApp Cloud sends string keys, Twilio symbol keys and a
# `media_content_type` instead of `media_type`), so callers hand us the raw referral hash
# and this builder normalizes it into one shape.
# rubocop:disable Metrics/ModuleLength
module Ctwa::CampaignBuilder
  module_function

  CTWA_SOURCE = 'meta_ctwa'.freeze
  ORGANIC_SOURCE = 'meta_organic'.freeze
  # Caps the append-only touch list so click storms can't grow the conversation jsonb
  # without bound (the length validator skips Array values, so this is the only fence).
  MAX_TOUCHES = 20
  # Slim per-touch projection: the full campaign shape minus `body` (origin keeps it).
  TOUCH_KEYS = %w[
    source source_id source_type source_url headline media_type ctwa_clid gclid fbclid ttclid utm_source utm_medium utm_campaign
    utm_term utm_content inferred
  ].freeze

  # Builds the unified campaign attribution hash, or nil when the referral carries no
  # usable attribution signal.
  def build(referral)
    return if referral.blank?

    ref = referral.to_h.symbolize_keys
    return if ref[:source_id].blank? && ref[:ctwa_clid].blank? && ref[:source_url].blank?

    ref = normalize_source_url_referral(bound_source_url(ref))

    {
      'source' => source_for(ref),
      'source_id' => ref[:source_id],
      'source_type' => ref[:source_type],
      'source_url' => ref[:source_url],
      'headline' => ref[:headline],
      'body' => ref[:body],
      'media_type' => ref[:media_type] || ref[:media_content_type],
      'ctwa_clid' => ref[:ctwa_clid]
    }.merge(tracking_attributes(ref)).compact
  end

  # Records the CTWA touch on the conversation. The first touch becomes the `campaign`
  # origin; later clicks append to `campaign_touches`. Idempotent per click: a touch whose
  # `ctwa_clid` (or `source_id` when the click id is absent) was already seen is a no-op,
  # so webhook redeliveries never duplicate touches.
  #
  # Webhooks are concurrent and retried, so the write is guarded by a row lock and the
  # dedup check re-runs inside it, avoiding a lost update on additional_attributes.
  def attribute!(conversation, referral)
    touch = build(referral)
    return false if touch.blank?
    # Cheap duplicate pre-check keeps redeliveries from taking the row lock — but only
    # once the record is already multi-touch. A legacy single-touch row (prod data from
    # before multi-touch) must still take the lock so migrate-on-write seeds
    # `campaign_touches` even when the click itself is a duplicate.
    return false if deduped_multi_touch?(conversation, touch)

    # reload discards the in-memory `display_id` set by the DB trigger, which `with_lock`
    # would otherwise reject as an unpersisted change.
    persisted = persist_touch(conversation, touch)
    # Cards mirror the conversation's campaign data, so linked cards re-broadcast after
    # a write to keep board pills/filters live (job no-ops without linked cards).
    Crm::Cards::RebroadcastConversationCardsJob.perform_later(conversation.id) if persisted && Crm::Config.enabled?

    persisted
  end

  # Current touch list; a legacy single-touch record (`campaign` written before
  # multi-touch shipped, no `campaign_touches` key) is migrated on the fly into a
  # one-item list stamped with the conversation creation time (best approximation).
  def existing_touches(conversation)
    attrs = conversation.additional_attributes
    return Array(attrs['campaign_touches']) if attrs.key?('campaign_touches')
    return [] if attrs['campaign'].blank?

    [slim_touch(attrs['campaign'], conversation.created_at.utc.iso8601)]
  end

  def campaign_attributes(conversation, touch, touches)
    conversation.additional_attributes.merge(
      'campaign' => campaign_origin(conversation, touch, touches),
      'campaign_touches' => touches,
      'campaign_source_ids' => touches.filter_map { |item| item['source_id'].presence }.uniq
    )
  end

  # The origin keeps the full shape (including `body`) and is only set by the first
  # touch; a pre-existing origin just gains `touched_at` (migrate-on-write of legado).
  def campaign_origin(conversation, touch, touches)
    origin = conversation.additional_attributes['campaign'].presence || touch
    origin.merge('touched_at' => origin['touched_at'] || touches.first['touched_at'])
  end

  def slim_touch(touch, touched_at)
    touch.slice(*TOUCH_KEYS).merge('touched_at' => touch['touched_at'] || touched_at)
  end

  def persist_touch(conversation, touch)
    persisted = false

    conversation.reload.with_lock do
      persisted = append_touch(conversation, touch)
    end

    persisted
  end

  def append_touch(conversation, touch)
    legacy = !conversation.additional_attributes.key?('campaign_touches')
    touches = existing_touches(conversation)
    duplicate = duplicate_touch?(touches, touch)
    return false if skip_touch?(duplicate, legacy, touches)

    touches += [slim_touch(touch, Time.current.utc.iso8601)] unless duplicate
    conversation.update!(additional_attributes: campaign_attributes(conversation, touch, touches))
  end

  def skip_touch?(duplicate, legacy, touches)
    (duplicate && !legacy) || (!duplicate && touches.length >= MAX_TOUCHES)
  end

  def tracking_attributes(ref)
    {
      'gclid' => ref[:gclid],
      'fbclid' => ref[:fbclid],
      'ttclid' => ref[:ttclid],
      'utm_source' => ref[:utm_source],
      'utm_medium' => ref[:utm_medium],
      'utm_campaign' => ref[:utm_campaign],
      'utm_term' => ref[:utm_term],
      'utm_content' => ref[:utm_content],
      'inferred' => ref[:inferred]
    }
  end

  MAX_SOURCE_URL_LENGTH = 512
  MAX_DERIVED_CODE_LENGTH = 40

  # External webhook input: the URL is bounded for EVERY referral shape before anything
  # derives from it or persists it into the conversation jsonb.
  def bound_source_url(ref)
    return ref if ref[:source_url].blank?

    ref.merge(source_url: ref[:source_url].to_s.first(MAX_SOURCE_URL_LENGTH))
  end

  # source_url arrives already bounded by build; only derivation happens here.
  def normalize_source_url_referral(ref)
    return ref unless source_url_only_referral?(ref)

    source_url = ref[:source_url].to_s
    code = source_url[%r{instagram\.com/(?:p|reel)/([\w-]+)}i, 1]&.first(MAX_DERIVED_CODE_LENGTH)
    ref.merge(
      source_id: source_url_source_id(source_url, code),
      source_type: ref[:source_type].presence || 'post',
      headline: ref[:headline].presence || source_url_headline(source_url, code)
    )
  end

  def source_url_only_referral?(ref)
    ref[:source_id].blank? && ref[:ctwa_clid].blank? && ref[:source_url].present?
  end

  def source_url_source_id(source_url, code)
    return "post:#{code}" if code.present?

    "url:#{Digest::SHA1.hexdigest(source_url)[0, 12]}"
  end

  # A malformed URL must never break inbound message processing, so the parse failure
  # (and a host-less URL) falls back to a bounded slice of the raw value.
  def source_url_headline(source_url, code)
    return "Post #{code}" if code.present?

    URI.parse(source_url).host.presence || source_url.first(40)
  rescue URI::InvalidURIError
    source_url.first(40)
  end

  def source_for(ref)
    return CTWA_SOURCE if ref[:ctwa_clid].present? || ref[:source_type].to_s == 'ad'
    return 'google_ads' if ref[:gclid].present?
    return 'tiktok_ads' if ref[:ttclid].present?
    return 'meta_paid' if ref[:fbclid].present?
    return 'tracked_link' if %w[tracked_link bridge].include?(ref[:source_type].to_s)

    ORGANIC_SOURCE
  end

  def duplicate_touch?(touches, touch)
    touches.any? { |existing| dedup_key(existing) == dedup_key(touch) }
  end

  def deduped_multi_touch?(conversation, touch)
    conversation.additional_attributes.key?('campaign_touches') && duplicate_touch?(existing_touches(conversation), touch)
  end

  # Paid Meta clicks prefer `ctwa_clid`; tracked-link bridge and organic referrals use
  # `source_id`, which still conservatively dedups retries without a clid.
  def dedup_key(touch)
    touch['ctwa_clid'].presence || touch['source_id'].presence
  end
end
# rubocop:enable Metrics/ModuleLength
