# Registers every phone with the Chatwoot Hub voice relay, so phones registered while the hub was
# unreachable, or before the relay was set up, are added. Runs daily, a batch a minute to stay
# inside the hub's registration quota.
class Voice::RelayDeviceReconcileJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 50

  def perform(after_id = 0)
    return unless ChatwootHub.voice_relay_secret

    batch = NotificationSubscription.where(subscription_type: %w[apns_voip fcm]).where('id > ?', after_id).order(:id).limit(BATCH_SIZE).to_a
    batch.each { |subscription| sync(subscription) }
    self.class.set(wait: 1.minute).perform_later(batch.last.id) if batch.size == BATCH_SIZE
  end

  private

  def sync(subscription)
    platform = Voice::RelayDeviceSync.platform_for(subscription)
    token = subscription.subscription_attributes['push_token']
    return if platform.nil? || token.blank?

    Voice::RelayDeviceSync.new(platform: platform, token: token).perform
  rescue RestClient::Conflict
    Rails.logger.warn("[VOIP PUSH] #{platform} device is registered to another installation on the hub relay")
  end
end
