# Sends a native inbox's current connect request (its proxy among it) to the connector, by
# connecting the session again.
# Enqueued by Whatsapp::Session::ChannelExtension when the proxy changes, and by
# Migration::NativeCallPolicyJob, since the connect states the whole desired state; this only
# checks, at send time, that there is still a session to resume.
class Whatsapp::Session::ApplyProxyJob < ApplicationJob
  queue_as :high

  # A Redis that is down, or a connector fleet speaking another protocol: the frame was not
  # written, so a later attempt can still deliver it.
  retry_on Whatsapp::Session::Errors::ProviderUnavailable, wait: :polynomially_longer, attempts: 5

  def perform(channel_id)
    channel = Channel::Whatsapp.find_by(id: channel_id)
    return unless channel&.resumable_session?

    channel.reassert_desired_state
  end
end
