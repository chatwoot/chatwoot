# Where a `uazapi` instance delivers its events.
#
# Two independent secrets have to match, because each covers what the other cannot. The
# path carries a token generated per inbox, which proves the caller was told where to
# post; the body carries the instance token, which proves it is the instance this inbox
# is configured for. A URL that leaks through a proxy log is not enough on its own, and
# neither is knowing an instance token without knowing which inbox it belongs to.
#
# Nothing here reads the payload beyond that check: an unknown event type is the
# translator's business, and a body this build cannot read must not turn into a non-2xx
# the provider would keep redelivering.
class Webhooks::Whatsapp::UazapiController < ActionController::API
  def process_payload
    return head :not_found if channel.blank?
    return head :unauthorized unless authentic?

    # The instance this body was authenticated against, so a job dispatched after the
    # inbox was re-pointed can tell that it belongs to the one before.
    Webhooks::WhatsappSessionEventsJob.perform_later(channel, event_payload,
                                                     Whatsapp::Session::Registry.instance_fingerprint(channel))
    head :ok
  end

  private

  def channel
    return @channel if defined?(@channel)

    @channel = Channel::Whatsapp.find_by(id: params[:channel_id], provider: 'uazapi')
  end

  def authentic?
    matches?(params[:webhook_token], provider_config['webhook_verify_token']) &&
      matches?(params[:token], provider_config['token'])
  end

  def provider_config
    channel.provider_config || {}
  end

  # Constant time, and never against a blank expectation: an inbox saved without its
  # token would otherwise accept anything that also sends nothing.
  def matches?(given, expected)
    return false if given.blank? || expected.blank?

    ActiveSupport::SecurityUtils.secure_compare(given.to_s, expected.to_s)
  end

  # The body as it arrived, minus the credential it echoes back. The token has served its
  # purpose by the time this runs, and leaving it in would carry it into a job argument,
  # its retries, and whatever logs those pass through.
  def event_payload
    request.request_parameters.except('token')
  end
end
