class Webhooks::FacebookEventsJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 1.second, attempts: 8

  def perform(message)
    response = ::Integrations::Facebook::MessageParser.new(message)

    key = format(::Redis::Alfred::FACEBOOK_MESSAGE_MUTEX, sender_id: response.sender_id, recipient_id: response.recipient_id)
    with_lock(key) do
      process_message(response)
    end
  end

  def process_message(response)
    # Xử lý referral events trước khi tạo message
    if response.referral?
      process_referral_event(response)
    else
      ::Integrations::Facebook::MessageCreator.new(response).perform
    end
  end

  private

  def process_referral_event(response)
    # Tìm inbox từ recipient_id
    inbox = ::Channel::FacebookPage.find_by(page_id: response.recipient_id)&.inbox
    return unless inbox

    # Tìm hoặc tạo contact_inbox
    contact_inbox = ::ContactInboxBuilder.new(
      source_id: response.sender_id,
      inbox: inbox,
      contact_attributes: {
        name: response.sender_name || response.sender_id
      }
    ).perform

    # Xử lý referral data
    Facebook::ReferralProcessorService.new(
      inbox: inbox,
      contact_inbox: contact_inbox,
      params: response.params
    ).perform

    Rails.logger.info("Processed Facebook referral event for sender #{response.sender_id}")
  end
end
