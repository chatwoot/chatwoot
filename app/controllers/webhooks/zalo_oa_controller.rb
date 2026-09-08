class Webhooks::ZaloOaController < ActionController::API
  def process_payload
    channel = find_channel
    return head :ok if channel.blank?
    return head :ok unless valid_signature?(channel)

    event = params.to_unsafe_hash.except('controller', 'action')
    if echo_event?
      # Add delay to prevent race condition where echo arrives before send message API completes
      # This avoids duplicate messages when echo comes early during API processing
      ::Webhooks::ZaloOaEventsJob.set(wait: 2.seconds).perform_later(event)
    else
      ::Webhooks::ZaloOaEventsJob.perform_later(event)
    end

    head :ok
  end

  private

  def echo_event?
    params[:event_name].to_s.start_with?('oa_')
  end

  def find_channel
    Channel::ZaloOa.find_by(oa_id: oa_id_from_payload) if oa_id_from_payload.present?
  end

  def oa_id_from_payload
    @oa_id_from_payload ||= if params[:event_name].to_s.start_with?('user_')
                              params.dig(:recipient, :id).to_s
                            else
                              params.dig(:sender, :id).to_s
                            end
  end

  # mac = hex SHA256(app_id + raw_body + timestamp + oa_secret_key), sent as `mac=<hex>`.
  def valid_signature?(channel)
    expected = Digest::SHA256.hexdigest(
      "#{channel.app_id}#{request.raw_post}#{params[:timestamp]}#{channel.oa_secret_key}"
    )
    ActiveSupport::SecurityUtils.secure_compare(expected, received_mac)
  end

  def received_mac
    request.headers['X-ZEvent-Signature'].to_s.delete_prefix('mac=')
  end
end
