# Delete migration and spec after 2 consecutive releases.
class Migration::PopulateContactVerificationJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options queue: :scheduled_jobs, timeout: 3_600 # 1 hour

  def perform
    updated_count = 0

    Contact.find_each(batch_size: 1000) do |contact|
      next if contact.is_verified
      next unless should_verify_contact?(contact)

      contact.update_columns(is_verified: true) # rubocop:disable Rails/SkipsModelValidations
      updated_count += 1
    end

    Rails.logger.info "[PopulateContactVerificationJob] Updated #{updated_count} contacts to verified"
  end

  private

  def should_verify_contact?(contact)
    verification_attributes?(contact) || social_channel_inbox?(contact)
  end

  def verification_attributes?(contact)
    contact.email.present? ||
      contact.phone_number.present? ||
      contact.identifier.present?
  end

  def social_channel_inbox?(contact)
    contact.inboxes.any? { |inbox| social_channel?(inbox) }
  end

  def social_channel?(inbox)
    inbox.facebook? || inbox.instagram? || inbox.instagram_direct? ||
      inbox.twitter? || inbox.line? || inbox.whatsapp? ||
      inbox.telegram?
  end
end
