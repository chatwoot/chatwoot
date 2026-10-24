# A phone's call-push token, registered with the Chatwoot Hub voice relay when the installation
# uses it, and removed from it once no subscription holds the token
module Enterprise::Concerns::NotificationSubscription
  extend ActiveSupport::Concern

  included do
    after_commit :sync_voice_relay_devices
  end

  private

  def sync_voice_relay_devices
    return unless ChatwootHub.voice_relay_secret

    platform = Voice::RelayDeviceSync.platform_for(self)
    return unless platform

    tokens = [subscription_attributes['push_token']]
    tokens << subscription_attributes_before_last_save&.dig('push_token') if saved_change_to_subscription_attributes?
    revision = Voice::RelayDeviceSync.revision
    tokens.compact_blank.uniq.each { |token| Voice::RelayDeviceSyncJob.perform_later(platform, token, revision) }
  end
end
