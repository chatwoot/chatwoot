# Retries failed WhatsApp template messages with 24-hour exponential backoff.
#
# Runs hourly via sidekiq-cron. For each failed template message created
# within the last 7 days, it checks eligibility (retry count, backoff delay,
# contact reply, template existence) before attempting to resend.
#
# Metadata stored in content_attributes:
#   retry_count     - number of retry attempts so far (0-7)
#   last_failed_at  - ISO8601 timestamp of the most recent failure
#   retry_abandoned - reason for permanent abandonment:
#                     'contact_replied' | 'template_not_found' | 'max_retries'
class RetryWhatsappTemplateMessagesJob < ApplicationJob
  queue_as :low

  MAX_RETRIES = 7
  RETRY_INTERVAL = 24.hours
  # 8 days: 7 retries * 24h interval + 24h buffer for the last retry to be attempted
  MAX_AGE = 8.days

  def perform
    eligible_messages.find_each do |message|
      process_message(message)
    rescue StandardError => e
      Rails.logger.error(
        "RetryWhatsappTemplate: unexpected error for Message##{message.id}: #{e.message}"
      )
    end
  end

  private

  def eligible_messages
    Message
      .where(status: :failed)
      .where('created_at >= ?', MAX_AGE.ago)
      .where("additional_attributes ->> 'template_params' IS NOT NULL")
  end

  def process_message(message)
    attrs = message.content_attributes || {}
    retry_count = attrs['retry_count'] || 0

    return if attrs['retry_abandoned'].present?
    return if retry_count >= MAX_RETRIES

    return abandon!(message, 'template_not_found') unless template_exists?(message)
    return abandon!(message, 'contact_replied') if contact_replied_after?(message)
    return unless retry_delay_elapsed?(message, retry_count)

    attempt_retry(message, retry_count)
  end

  def template_exists?(message)
    channel = message.conversation&.inbox&.channel
    return false unless channel.is_a?(Channel::Whatsapp)

    tp = message.additional_attributes['template_params']
    name = tp['name']
    language = tp['language']

    channel.message_templates&.any? do |t|
      t['name'] == name && t['language'] == language && t['status']&.downcase == 'approved'
    end
  end

  def contact_replied_after?(message)
    message.conversation.messages.incoming
           .where('created_at > ?', message.created_at)
           .exists?
  end

  def retry_delay_elapsed?(message, retry_count)
    required_delay = (retry_count + 1) * RETRY_INTERVAL
    Time.current >= message.created_at + required_delay
  end

  def attempt_retry(message, retry_count)
    service = Whatsapp::SendOnWhatsappService.new(message: message)
    service.perform

    # Success: if the message status was updated by perform_reply (e.g. source_id set),
    # we still ensure it is marked as sent and retry metadata is cleaned up.
    message.reload
    message.update!(
      status: :sent,
      content_attributes: message.content_attributes.except('retry_count', 'last_failed_at', 'retry_abandoned')
    )
  rescue StandardError => e
    new_count = retry_count + 1
    attrs = (message.content_attributes || {}).merge(
      'retry_count' => new_count,
      'last_failed_at' => Time.current.iso8601
    )
    attrs['retry_abandoned'] = 'max_retries' if new_count >= MAX_RETRIES

    message.update!(content_attributes: attrs)

    Rails.logger.warn(
      "RetryWhatsappTemplate: attempt #{new_count}/#{MAX_RETRIES} " \
      "failed for Message##{message.id}: #{e.message}"
    )
  end

  def abandon!(message, reason)
    attrs = (message.content_attributes || {}).merge('retry_abandoned' => reason)
    message.update!(content_attributes: attrs)

    Rails.logger.info(
      "RetryWhatsappTemplate: abandoned Message##{message.id}, reason: #{reason}"
    )
  end
end
