class Sms::TelnyxDeliveryStatusService
  pattr_initialize [:inbox!, :params!]

  def perform
    return unless message

    message.status = delivery_status
    message.external_error = error_detail if failed?
    message.save!
  end

  private

  def delivery_status
    to_status = params.dig('to', 0, 'status')
    failed_statuses = %w[failed gw_timeout]
    failed_statuses.include?(to_status) ? 'failed' : 'delivered'
  end

  def failed?
    delivery_status == 'failed'
  end

  def error_detail
    errors = Array(params['errors'])
    return nil if errors.empty?

    "#{errors.first['code']} - #{errors.first['title']}"
  end

  def message
    @message ||= inbox.messages.find_by(source_id: params['id'])
  end
end
