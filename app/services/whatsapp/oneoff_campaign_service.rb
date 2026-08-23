class Whatsapp::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign!
    process_audience(extract_audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def validate_campaign_type!
    raise "Invalid campaign #{campaign.id}" unless whatsapp_campaign? && campaign.one_off?
  end

  def whatsapp_campaign?
    campaign.inbox.channel.is_a?(Channel::Whatsapp)
  end

  def validate_campaign_status!
    raise 'Completed Campaign' if campaign.completed?
  end

  def validate_provider!
    # Unofficial (Baileys/QR) WhatsApp sends free-form text — no template approval,
    # no 24h window — so it is a valid campaign target alongside the Cloud API.
    return if %w[whatsapp_cloud whatsapp_unofficial].include?(channel.provider)

    raise 'WhatsApp Cloud provider required'
  end

  def validate_feature_flag!
    return if channel.provider == 'whatsapp_unofficial'

    raise 'WhatsApp campaigns feature not enabled' unless campaign.account.feature_enabled?(:whatsapp_campaign)
  end

  def validate_campaign!
    validate_campaign_type!
    validate_campaign_status!
    validate_provider!
    validate_feature_flag!
  end

  def extract_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end

  # Instead of sending every message inline, one job per recipient is scheduled
  # ahead of time. The gaps between sends are randomized and every batch gets an
  # extra pause, so the traffic pattern looks human instead of a bulk blast —
  # bulk-blast patterns are what get WhatsApp numbers flagged and banned.
  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
                       .where(eligible_recipient_clause).order(:id)
    total_count = contacts.count
    Rails.logger.info "Scheduling #{total_count} contacts for WhatsApp campaign #{campaign.id}"
    return if total_count.zero?

    # Clear any stale tracking from a previous trigger/retry
    Redis::Alfred.delete("campaign:#{campaign.id}:whatsapp_dispatch_processed")
    Redis::Alfred.delete("campaign:#{campaign.id}:whatsapp_dispatch_processed_set")
    Redis::Alfred.setex("campaign:#{campaign.id}:whatsapp_dispatch_total", total_count, Campaigns::WhatsappContactJob::REDIS_KEY_EXPIRY)

    schedule_dispatch(contacts)
  end

  # A contact is targetable if it has a phone number, or — for the unofficial
  # provider — a WhatsApp JID source_id in this inbox (LID peers have no real
  # phone number but can still be messaged via their JID).
  def eligible_recipient_clause
    return Contact.arel_table[:phone_number].not_eq(nil).and(Contact.arel_table[:phone_number].not_eq('')) unless channel.provider == 'whatsapp_unofficial'

    phone_present = Contact.arel_table[:phone_number].not_eq(nil).and(Contact.arel_table[:phone_number].not_eq(''))
    has_source_id = Contact.arel_table[:id].in(
      ContactInbox.where(inbox_id: inbox.id).where.not(source_id: [nil, '']).select(:contact_id)
    )
    phone_present.or(has_source_id)
  end

  def schedule_dispatch(contacts)
    dispatch_at = Time.current
    sent_in_current_batch = 0

    contacts.find_each do |contact|
      dispatch_at += rand(min_delay_seconds..max_delay_seconds).seconds
      sent_in_current_batch += 1

      if sent_in_current_batch == batch_size
        dispatch_at += rand(min_batch_pause_minutes..max_batch_pause_minutes).minutes
        sent_in_current_batch = 0
      end

      Campaigns::WhatsappContactJob.set(wait_until: dispatch_at).perform_later(campaign.id, contact.id)
    end
  end

  # Anti-ban pacing knobs. ENV-overridable so throughput can be tuned per
  # deployment without a code change.
  def min_delay_seconds
    ENV.fetch('WHATSAPP_CAMPAIGN_MIN_DELAY_SECONDS', '20').to_i
  end

  def max_delay_seconds
    ENV.fetch('WHATSAPP_CAMPAIGN_MAX_DELAY_SECONDS', '60').to_i
  end

  def batch_size
    ENV.fetch('WHATSAPP_CAMPAIGN_BATCH_SIZE', '50').to_i
  end

  def min_batch_pause_minutes
    ENV.fetch('WHATSAPP_CAMPAIGN_MIN_BATCH_PAUSE_MINUTES', '5').to_i
  end

  def max_batch_pause_minutes
    ENV.fetch('WHATSAPP_CAMPAIGN_MAX_BATCH_PAUSE_MINUTES', '10').to_i
  end
end
