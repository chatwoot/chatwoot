# Triggers the WhatsApp Coexistence contacts + messaging-history sync right after
# Embedded Signup completes. Meta gives a hard 24h window from onboarding to fire these,
# and only one sync attempt per onboarding cycle — so this runs inline at the end of the
# signup flow, not on a delayed batch job.
#
# History is best-effort: onboarding must NEVER fail because of it, so every error is
# swallowed and logged. Idempotent: once a sync has been requested for a channel we skip
# re-firing (a fresh onboarding creates a new channel and re-fires naturally).
#
# Sync order is mandated by Meta: contacts (sync_type=smb_app_state_sync) first, then history.
# https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/onboarding-business-app-users
class Whatsapp::HistorySyncService
  SYNC_TYPES = %w[smb_app_state_sync history].freeze

  def initialize(channel)
    @channel = channel
  end

  def perform
    return unless Whatsapp::HistorySync.enabled?
    return unless coexistence_channel?
    return if already_requested?

    request_ids = SYNC_TYPES.index_with { |sync_type| trigger_sync(sync_type) }
    persist_request_ids(request_ids)
  rescue StandardError => e
    # History sync is best-effort — never break onboarding.
    Rails.logger.error("[WHATSAPP] History sync trigger failed for #{@channel&.phone_number}: #{e.message}")
  end

  private

  def coexistence_channel?
    (@channel.provider_config || {}).to_h['source'] == 'embedded_signup'
  end

  def already_requested?
    (@channel.provider_config || {}).to_h['history_sync_requested_at'].present?
  end

  def trigger_sync(sync_type)
    phone_number_id = @channel.provider_config['phone_number_id']
    access_token = @channel.provider_config['api_key']
    response = Whatsapp::FacebookApiClient.new(access_token).start_smb_app_data_sync(phone_number_id, sync_type)
    request_id = response.is_a?(Hash) ? response['request_id'] : nil
    Rails.logger.info("[WHATSAPP] History sync '#{sync_type}' requested for #{@channel.phone_number} (request_id=#{request_id})")
    request_id
  end

  def persist_request_ids(request_ids)
    @channel.provider_config['history_sync_requested_at'] = Time.current.iso8601
    @channel.provider_config['history_sync_request_ids'] = request_ids
    @channel.save!
  end
end
