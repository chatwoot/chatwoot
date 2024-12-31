# app/services/whatsapp/campaign_service.rb
class Whatsapp::WhatsappCampaignService
  include Rails.application.routes.url_helpers

  BATCH_SIZE = 100 # Process contacts in batches
  RATE_LIMIT = 60 # Messages per minute (adjust based on your WhatsApp provider)

  attr_reader :campaign, :processed_count, :failed_count

  def initialize(campaign:)
    @campaign = campaign
    @processed_count = 0
    @failed_count = 0
    @start_time = Time.current
  end

  def perform
    # Check if campaign can be processed
    return if campaign.completed?

    # Rest of the method remains the same
    process_contacts_in_batches
    update_campaign_metrics
    campaign.completed!
  rescue StandardError => e
    campaign.update(campaign_status: :completed)
    Rails.logger.error "Campaign #{campaign.id} failed: #{e.message}"
    notify_admin_of_failure(e)
  end

  private

  def process_contacts_in_batches
    campaign.campaign_contacts.pending.find_each(batch_size: BATCH_SIZE) do |campaign_contact|
      process_contact(campaign_contact)
      respect_rate_limit
    end
  end

  def process_contact(campaign_contact)
    send_template_message(campaign_contact)
    @processed_count += 1
  rescue StandardError => e
    handle_contact_failure(campaign_contact, e)
    @failed_count += 1
  end

  def send_template_message(campaign_contact)
    template = fetch_template
    raise 'Template not found' if template.nil?
    response = send_message_to_contact(campaign_contact, template)
    update_contact_status(campaign_contact, response)
  rescue StandardError => e
    handle_contact_failure(campaign_contact, e)
    raise
  end

  def fetch_template
    find_template(campaign.template_id)
  end

  def send_message_to_contact(campaign_contact, template) 
    whatsapp_client.send_template(
      campaign_contact.contact.phone_number,
      template_payload(template,campaign_contact.contact.name)
    )
  end

  def template_payload(template, name)
    # Check if any component contains the 'example' key
    example_present = template['components'].any? { |component| component.key?('example') }
  
    # Build the payload with or without 'parameters' key based on 'example' presence
    payload = {
      name: template['name'], # e.g., 'hello_world'
      lang_code: template['language'] # e.g., 'en_US'
    }
  
    if example_present
      payload[:parameters] = [{
        "type": "text",
        "text": name
      }]
    end
  
    payload
  end
  

  def find_template(template_id)
    return nil if campaign.inbox.channel&.message_templates.blank?

    campaign.inbox.channel.message_templates.find do |template|
      template['id'].to_s == template_id.to_s
    end
  end

  def whatsapp_client
    @whatsapp_client ||= begin
      client = Whatsapp::Providers::WhatsappCloudService.new(
        whatsapp_channel: campaign.inbox.channel
      )
      client
    end
  end

  def build_template_parameters(contact)
    {
      name: contact.name
      # Add other template parameters based on your needs
      #   tracking_url: generate_tracking_url(contact)
    }
  end

  def update_contact_status(campaign_contact, response)
    campaign_contact.update!(
      status: 'processed',
      processed_at: Time.current,
      message_id: response
    )
  end

  def handle_contact_failure(campaign_contact, error)
    campaign_contact.update!(
      status: 'failed',
      processed_at: Time.current,
      error_message: error.message
    )

    Rails.logger.error(
      "Failed to process contact #{campaign_contact.contact_id} " \
      "for campaign #{campaign.id}: #{error.message}"
    )
  end

  def update_campaign_metrics
    campaign.update!(
      processed_contacts_count: @processed_count,
      failed_contacts_count: @failed_count
    )
  end

  def respect_rate_limit
    messages_sent = @processed_count + @failed_count
    expected_duration = messages_sent.to_f / RATE_LIMIT * 60
    actual_duration = Time.current - @start_time

    return unless actual_duration < expected_duration

    sleep(expected_duration - actual_duration)
  end

  def notify_admin_of_failure(error)
    AdminNotifier.campaign_failure(
      campaign_id: campaign.id,
      error: error.message,
      backtrace: error.backtrace&.first(5)
    ).deliver_later
  end

  def generate_tracking_url(contact)
    campaign_tracking_url(
      campaign_id: campaign.id,
      contact_id: contact.id,
      token: generate_tracking_token(contact)
    )
  end

  def generate_tracking_token(contact)
    JWT.encode(
      {
        campaign_id: campaign.id,
        contact_id: contact.id,
        exp: 30.days.from_now.to_i
      },
      Rails.application.secrets.secret_key_base
    )
  end
end
