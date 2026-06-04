class Whatsapp::OneoffUnoapiCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if inbox.inbox_type != 'Whatsapp' || channel.provider != 'unoapi' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    # marks campaign completed so that other jobs won't pick it up
    campaign.completed!

    process_audience(campaign.audience)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience)
    Rails.logger.debug { "Process campaign #{campaign.id} and #{audience.length} audience record(s)" }
    interval = 0
    new_audience = audience.map do |a|
      aa = update_audience(a.symbolize_keys)
      interval = schedule_job(campaign, aa, interval) if aa[:status] == :scheduled
      aa
    end
    # rubocop:disable Rails/SkipsModelValidations
    campaign.update_column(:audience, new_audience)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def update_audience(audience)
    audience[:status] = audience[:phone_number].present? ? :scheduled : :error
    audience[:audience_id] = audience[:audience_id] || SecureRandom.uuid
    audience.symbolize_keys
  end

  def schedule_job(campaign, audience, interval)
    interval = audience[:wait_for_seconds] || (interval + rand(1..10))
    CampaignMessageJob.set(wait: interval.seconds).perform_later(
      campaign.account_id,
      campaign.inbox_id,
      campaign.id,
      campaign.message,
      audience
    )
    interval
  end
end
