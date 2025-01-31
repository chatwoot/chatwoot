# whatsapp_campaign_job.rb

class WhatsappCampaignJob < ApplicationJob
    queue_as :whatsapp_messages
    retry_on StandardError, wait: :exponentially_longer, attempts: 3
    
    DELAY_BETWEEN_MESSAGES = 10
    LOCK_TIMEOUT = 30 # seconds
    LOCK_WAIT_TIMEOUT = 60 # Maximum time to wait for lock
    SEQUENCE_CHECK_INTERVAL = 0.5 # Time between sequence checks
    MAX_EXECUTION_TIME = 15 # Maximum time allowed for message processing
    
    def perform(campaign_contact_id:, campaign_id:, sequence_number:)
      
      
      unless wait_and_acquire_lock(campaign_id, sequence_number)
        
        retry_job wait: 5.seconds
        return
      end
      
      begin
        Timeout.timeout(MAX_EXECUTION_TIME) do
          campaign_contact = CampaignContact.find(campaign_contact_id)
          campaign = Campaign.find(campaign_id)
          
          enforce_timing(campaign_id, sequence_number)
          process_contact(campaign_contact, campaign)
          update_sequence(campaign_id, sequence_number)
        end
      rescue Timeout::Error => e
        
        handle_job_failure(campaign_contact, e)
        raise
      rescue StandardError => e
        
        handle_job_failure(campaign_contact, e)
        raise
      ensure
        release_lock(campaign_id, sequence_number)
        
      end
    end
    
    private
    
    def wait_and_acquire_lock(campaign_id, sequence_number)
      start_time = Time.current
      
      while Time.current - start_time < LOCK_WAIT_TIMEOUT
        if wait_for_sequence(campaign_id, sequence_number)
          if acquire_lock(campaign_id, sequence_number)
            return true
          end
        end
        sleep(SEQUENCE_CHECK_INTERVAL)
      end
      
      false
    end
    
    def wait_for_sequence(campaign_id, sequence_number)
      Sidekiq.redis do |redis|
        last_processed = (redis.get("campaign:#{campaign_id}:last_processed") || "0").to_i
        expected_previous = sequence_number - 1
        
        if last_processed == expected_previous
          return true
        end
        
        
        false
      end
    end
    
    def enforce_timing(campaign_id, sequence_number)
      Sidekiq.redis do |redis|
        start_time = redis.get("campaign:#{campaign_id}:start_time").to_f
        expected_time = Time.at(start_time + (sequence_number - 1) * DELAY_BETWEEN_MESSAGES)
        current_time = Time.current
        
        if current_time < expected_time
          sleep_duration = expected_time - current_time
          sleep(sleep_duration)
        end
      end
    end
    
    def acquire_lock(campaign_id, sequence_number)
      Sidekiq.redis do |redis|
        lock_key = "campaign:#{campaign_id}:lock"
        # Use SET NX with expiration to ensure atomic lock acquisition
        result = redis.set(lock_key, sequence_number.to_s, nx: true, ex: LOCK_TIMEOUT)
        !!result
      end
    end
    
    def release_lock(campaign_id, sequence_number)
      Sidekiq.redis do |redis|
        lock_key = "campaign:#{campaign_id}:lock"
        # Only release if we still own the lock
        current_lock = redis.get(lock_key)
        if current_lock == sequence_number.to_s
          redis.del(lock_key)
        end
      end
    end
    
    def update_sequence(campaign_id, sequence_number)
      Sidekiq.redis do |redis|
        redis.set("campaign:#{campaign_id}:last_processed", sequence_number)
      end
    end
    
    def process_contact(campaign_contact, campaign)
      return if campaign_contact.processed?
      
      template = fetch_template(campaign)
      

      # Check if template has an IMAGE header
      response = if has_image_header?(template)
        send_media_template_message(campaign_contact, template)
      else
        send_template_message(campaign_contact, template)
      end

      update_contact_status(campaign_contact, response)
    end

    def has_image_header?(template)
      template['components']&.any? do |component|
        component['type'] == 'HEADER' && component['format'] == 'IMAGE'
      end
    end

    def send_media_template_message(campaign_contact, template)
      begin
        header_component = template['components'].find { |c| c['type'] == 'HEADER' }
        image_url = header_component['example']['header_handle'].first

        
        whatsapp_client(campaign_contact.campaign.inbox).send_template(
          campaign_contact.contact.phone_number,
          build_media_template_payload(template, campaign_contact.contact.name, image_url)
        )
      rescue StandardError => e
        nil
      end
    end


    def build_media_template_payload(template, name, url)
      {
        name: template['name'],
        lang_code: template['language'],
        media: [
          {
            type: 'image',
            image: {
              link: url
            }
          }
        ],
        parameters: template['components'].any? { |c| c.key?('example') } ?
          [{ type: 'text',parameter_name: 'name', text: name }] :
          []
      }
    rescue StandardError => e
      build_template_payload(template, name)
    end
    
    def send_template_message(campaign_contact, template)
      whatsapp_client(campaign_contact.campaign.inbox).send_template(
        campaign_contact.contact.phone_number,
        build_template_payload(template, campaign_contact.contact.name)
      )
    end
    
    def build_template_payload(template, name)
      {
        name: template['name'],
        lang_code: template['language'],
        parameters: template['components'].any? { |c| c.key?('example') } ?
          [{ type: 'text', parameter_name: 'name', text: name }] :  # Changed 'key' to 'parameter_name'
          []
      }
    end
    
    def update_contact_status(campaign_contact, response)
      campaign_contact.update!(
        message_id: response,
        status: 'processed',
        processed_at: Time.current
      )
    end
    
    def handle_job_failure(campaign_contact, error)
      return unless campaign_contact
      
      campaign_contact.update!(
        status: 'failed',
        processed_at: Time.current,
        error_message: error.message
      )
      
      Rails.logger.error(
        "Failed to process contact #{campaign_contact.id}: #{error.message}"
      )
    end
    
    def whatsapp_client(inbox)
      @whatsapp_client ||= begin
        client = Whatsapp::Providers::WhatsappCloudService.new(
          whatsapp_channel: inbox.channel
        )
        client
      end
    end
    
    def fetch_template(campaign)
      campaign.inbox.channel.message_templates.find do |template|
        template['id'].to_s == campaign.template_id.to_s
      end
    end
  end