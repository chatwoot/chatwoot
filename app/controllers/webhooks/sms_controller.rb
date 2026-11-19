class Webhooks::SmsController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  APPLICATION_CREDENTIAL_LIMIT = 25

  def process_payload
    return head :ok if target_channel.blank? || !routable?
    return request_http_basic_authentication unless callback_authorized?

    Webhooks::SmsEventsJob.perform_later(event.to_unsafe_hash)
    head :ok
  end

  private

  def event
    @event ||= params['_json']&.first
  end

  def target_channel
    return @target_channel if defined?(@target_channel)

    to = event[:to] if event.is_a?(ActionController::Parameters)
    @target_channel = to.is_a?(String) ? Channel::Sms.find_by(phone_number: to) : nil
  end

  def route_channel
    return @route_channel if defined?(@route_channel)

    @route_channel = Channel::Sms.find_by(phone_number: "+#{params[:phone_number].to_s.delete_prefix('+')}")
  end

  # Inboxes sharing one Bandwidth application share its single callback URL.
  def routable?
    return true if route_channel.blank? || route_channel == target_channel
    return true if route_channel.shares_bandwidth_application?(target_channel)

    Rails.logger.warn("[SMS] callback for channel #{target_channel.id} dropped: routed to channel #{route_channel.id}")
    false
  end

  def callback_channels
    [target_channel, route_channel].compact.uniq
  end

  def application_channels
    application_id = target_channel.bandwidth_application_id
    return Channel::Sms.none if application_id.blank?

    Channel::Sms.where(account_id: target_channel.account_id)
                .on_bandwidth_application(application_id)
                .where.not(id: callback_channels.map(&:id))
                .limit(APPLICATION_CREDENTIAL_LIMIT)
  end

  def callback_authorized?
    authenticated = authenticate_with_http_basic do |username, password|
      valid = ->(channel) { channel.valid_callback_credentials?(username, password) }
      callback_channels.any?(&valid) || application_channels.any?(&valid)
    end
    return true if authenticated
    return false if callback_channels.any?(&:callback_auth_enforced?)

    Rails.logger.warn("[SMS] unauthenticated callback accepted for channel #{target_channel.id}")
    true
  end
end
