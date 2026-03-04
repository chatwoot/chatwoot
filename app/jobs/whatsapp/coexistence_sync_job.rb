# Initiates WhatsApp Business App coexistence data synchronization after embedded signup.
# This job calls the Meta API to request contacts and message history sync.
#
# Must be called within 24 hours of onboarding, otherwise the business must be
# offboarded and re-onboarded.
#
# Reference: https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/onboarding-business-app-users
class Whatsapp::CoexistenceSyncJob < ApplicationJob
  queue_as :default

  def perform(channel)
    @channel = channel
    @api_client = Whatsapp::FacebookApiClient.new(channel.provider_config['api_key'])
    phone_number_id = channel.provider_config['phone_number_id']

    return unless coexistence_enabled?(phone_number_id)

    update_coexistence_status('syncing')

    # Step 1: Initiate contacts synchronization
    sync_contacts(phone_number_id)

    # Step 2: Initiate message history synchronization
    sync_history(phone_number_id)

    Rails.logger.info "[WHATSAPP COEXISTENCE] Sync initiated for channel #{channel.phone_number}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP COEXISTENCE] Sync failed for channel #{channel.phone_number}: #{e.message}"
    update_coexistence_status('sync_failed', error: e.message)
  end

  private

  def coexistence_enabled?(phone_number_id)
    result = @api_client.check_coexistence_status(phone_number_id)
    is_coexistence = result['is_on_biz_app'] == true && result['platform_type'] == 'CLOUD_API'

    Rails.logger.info "[WHATSAPP COEXISTENCE] Phone number #{phone_number_id} is not in coexistence mode, skipping sync" unless is_coexistence

    is_coexistence
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP COEXISTENCE] Could not check coexistence status: #{e.message}"
    false
  end

  def sync_contacts(phone_number_id)
    result = @api_client.initiate_contacts_sync(phone_number_id)
    request_id = result['request_id']

    update_coexistence_config('contacts_sync_request_id', request_id)
    update_coexistence_config('contacts_sync_status', 'initiated')

    Rails.logger.info "[WHATSAPP COEXISTENCE] Contacts sync initiated (request_id: #{request_id})"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP COEXISTENCE] Contacts sync failed: #{e.message}"
    update_coexistence_config('contacts_sync_status', 'failed')
  end

  def sync_history(phone_number_id)
    result = @api_client.initiate_history_sync(phone_number_id)
    request_id = result['request_id']

    update_coexistence_config('history_sync_request_id', request_id)
    update_coexistence_config('history_sync_status', 'initiated')

    Rails.logger.info "[WHATSAPP COEXISTENCE] History sync initiated (request_id: #{request_id})"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP COEXISTENCE] History sync failed: #{e.message}"
    update_coexistence_config('history_sync_status', 'failed')
  end

  def update_coexistence_status(status, error: nil)
    config = @channel.provider_config.dup
    config['coexistence'] ||= {}
    config['coexistence']['status'] = status
    config['coexistence']['synced_at'] = Time.current.iso8601 if status == 'syncing'
    config['coexistence']['error'] = error if error
    @channel.update!(provider_config: config)
  end

  def update_coexistence_config(key, value)
    config = @channel.provider_config.dup
    config['coexistence'] ||= {}
    config['coexistence'][key] = value
    @channel.update!(provider_config: config)
  end
end
