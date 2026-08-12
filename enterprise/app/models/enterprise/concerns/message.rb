module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    has_one :call, dependent: :nullify
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async
    before_create :ensure_campaign_message_limit
  end

  # Only campaign-tagged messages (additional_attributes['campaign_id']) are
  # metered against the package's monthly campaign-message limit. The window is
  # the month-bucket anchored at the package start date, same as active chats.
  def ensure_campaign_message_limit
    return unless additional_attributes.present? && additional_attributes['campaign_id'].present?
    return unless account.present?

    limit = account.usage_limits[:campaign_messages]
    return if limit.blank?
    window = account.package_usage_window
    return unless window

    account.with_lock do
      count = account.messages
                     .where("additional_attributes->>'campaign_id' IS NOT NULL")
                     .where(created_at: window[0]...window[1]).count
      raise CustomExceptions::Message::CampaignLimitExceeded.new({}) if count >= limit
    end
  end
end
