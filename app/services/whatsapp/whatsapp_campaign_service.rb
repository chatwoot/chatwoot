# whatsapp_campaign_service.rb

class Whatsapp::WhatsappCampaignService
  include Rails.application.routes.url_helpers
  
  BATCH_SIZE = 50
  DELAY_BETWEEN_MESSAGES = 10 # seconds
  MAX_RETRY_ATTEMPTS = 3
  
  attr_reader :campaign, :processed_count, :failed_count
  
  def initialize(campaign:)
    @campaign = campaign
    @processed_count = 0
    @failed_count = 0
    @start_time = Time.current
  end
  
  def perform
    return if campaign.completed?
    
    Sidekiq.redis do |redis|
      # Ensure no other campaign execution is in progress
      return if redis.get("campaign:#{campaign.id}:in_progress") == "true"
      
      begin
        redis.set("campaign:#{campaign.id}:in_progress", "true")
        initialize_campaign_state
        process_all_contacts
        update_campaign_status
      ensure
        redis.set("campaign:#{campaign.id}:in_progress", "false")
      end
    end
  rescue StandardError => e
    handle_campaign_failure(e)
  end
  
  private
  
  def process_all_contacts
    total_pending = campaign.campaign_contacts.pending.count
    total_batches = (total_pending.to_f / BATCH_SIZE).ceil
    
    
    total_batches.times do |batch_number|
      process_batch(batch_number)
      # Add delay between batches to prevent overwhelming the system
      sleep(DELAY_BETWEEN_MESSAGES) if batch_number < total_batches - 1
    end
  end
  
  def process_batch(batch_number)
    offset = batch_number * BATCH_SIZE
    
    
    contacts = campaign.campaign_contacts.pending
                      .order(id: :asc)
                      .offset(offset)
                      .limit(BATCH_SIZE)
                      .to_a # Load all contacts at once to prevent timing issues
    
    total_scheduled = 0
    
    contacts.each do |campaign_contact|
      sequence_number = offset + total_scheduled + 1
      scheduled_time = calculate_schedule_time(sequence_number)
      
      
      schedule_contact_job(campaign_contact, sequence_number, scheduled_time)
      total_scheduled += 1
    end
    
  end
  
  def calculate_schedule_time(sequence_number)
    # Ensure precise timing by using the campaign start time as base
    base_time = @start_time
    delay = (sequence_number - 1) * DELAY_BETWEEN_MESSAGES
    base_time + delay.seconds
  end
  
  def schedule_contact_job(campaign_contact, sequence_number, scheduled_time)
    WhatsappCampaignJob.set(
      wait_until: scheduled_time,
      retry: MAX_RETRY_ATTEMPTS
    ).perform_later(
      campaign_contact_id: campaign_contact.id,
      campaign_id: campaign.id,
      sequence_number: sequence_number
    )
  end
  
  def initialize_campaign_state
    Sidekiq.redis do |redis|
      redis.multi do
        redis.del("campaign:#{campaign.id}:last_processed")
        redis.del("campaign:#{campaign.id}:lock") # Clear any existing locks
        redis.set("campaign:#{campaign.id}:start_time", @start_time.to_f.to_s)
      end
    end
  end
  
  def update_campaign_status
    campaign.update!(campaign_status: :completed)
  end
  
  def handle_campaign_failure(error)
    campaign.update!(campaign_status: :completed)
    Rails.logger.error("Campaign #{campaign.id} failed: #{error.message}")
    notify_admin_of_failure(error)
  end
end