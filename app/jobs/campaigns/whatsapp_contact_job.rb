# Sends one WhatsApp campaign message to one contact.
#
# Whatsapp::OneoffCampaignService schedules one of these jobs per recipient,
# spread out over time with randomized delays and batch pauses. Spreading sends
# keeps the traffic pattern human-like so Meta/the unofficial provider does not
# flag the number as spam and ban it.
class Campaigns::WhatsappContactJob < ApplicationJob
  queue_as :low

  REDIS_KEY_EXPIRY = 7.days

  def perform(campaign_id, contact_id)
    @campaign_id = campaign_id
    @contact_id = contact_id
    campaign = Campaign.find_by(id: campaign_id)
    contact = campaign&.account&.contacts&.find_by(id: contact_id)
    return if campaign.nil? || contact.nil?

    deliver_message(campaign, contact)
  ensure
    track_dispatch_progress if @campaign_id && @contact_id
  end

  private

  def deliver_message(campaign, contact)
    channel = campaign.inbox.channel

    if channel.provider == 'whatsapp_unofficial'
      send_unofficial_message(channel, campaign, contact)
    else
      send_template_message(channel, campaign, contact)
    end
  end

  # Unofficial WhatsApp has no templates: render the campaign's plain message
  # through Liquid and send it as free-form text.
  def send_unofficial_message(channel, campaign, contact)
    content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)
    return if content.blank?

    channel.provider_service.send_free_text(contact.phone_number, content)
  rescue StandardError => e
    Rails.logger.error "Failed to send unofficial WhatsApp message to #{contact.phone_number}: #{e.message}"
  end

  def send_template_message(channel, campaign, contact)
    if campaign.template_params.blank?
      Rails.logger.error "Skipping contact #{contact.name} - no template_params found for WhatsApp campaign"
      return
    end

    processed_template_params = process_liquid_template_params(campaign, contact)
    return if processed_template_params.nil?

    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: processed_template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call
    return if name.blank?

    channel.send_template(contact.phone_number, {
                            name: name,
                            namespace: namespace,
                            lang_code: lang_code,
                            parameters: processed_parameters
                          }, nil)
  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp template message to #{contact.phone_number}: #{e.message}"
    nil
  end

  def process_liquid_template_params(campaign, contact)
    Whatsapp::LiquidTemplateProcessorService.new(campaign: campaign, contact: contact)
                                            .process_template_params(campaign.template_params)
  rescue StandardError => e
    Rails.logger.error "Failed to process liquid template params for contact #{contact.name}: #{e.message}"
    nil
  end

  # Counts every dispatched recipient (success or failure) using a Redis set for
  # idempotency - retries for same contact do not double-count. When the last
  # unique recipient finishes, the campaign is marked completed and keys dropped.
  def track_dispatch_progress
    set_key = "campaign:#{@campaign_id}:whatsapp_dispatch_processed_set"
    # sadd is idempotent
    $alfred.with { |conn| conn.sadd(set_key, @contact_id) }
    $alfred.with { |conn| conn.expire(set_key, REDIS_KEY_EXPIRY) }

    # Keep incr counter for backwards compat / metrics
    processed_key = "campaign:#{@campaign_id}:whatsapp_dispatch_processed"
    Redis::Alfred.incr(processed_key)
    Redis::Alfred.expire(processed_key, REDIS_KEY_EXPIRY)

    processed_count = $alfred.with { |conn| conn.scard(set_key) }
    total_count = Redis::Alfred.get("campaign:#{@campaign_id}:whatsapp_dispatch_total").to_i
    return unless total_count.positive? && processed_count >= total_count

    Campaign.find_by(id: @campaign_id)&.completed!
    Redis::Alfred.delete(set_key)
    Redis::Alfred.delete(processed_key)
    Redis::Alfred.delete("campaign:#{@campaign_id}:whatsapp_dispatch_total")
  end
end
