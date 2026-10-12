module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    include ConversationMonitors::MessageTracking
    has_one :call, dependent: :nullify
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async

    after_create_commit :record_ad_referral
    after_create_commit :classify_sales_store
  end

  private

  def classify_sales_store
    return unless incoming? && !private?
    return unless SalesRouting::Configuration.new(inbox: inbox).enabled?
    return if conversation.additional_attributes[SalesRouting::Classifier::ATTRIBUTES_KEY].present?

    SalesRouting::ClassifyJob.set(wait: SalesRouting::Classifier::ENRICHMENT_WAIT).perform_later(conversation_id)
  end

  # Every channel that carries Meta ad attribution stores it under the same
  # `referral` key, so one hook covers WhatsApp, Messenger and Instagram.
  def record_ad_referral
    return unless incoming?
    return if content_attributes['referral'].blank?

    AdAttribution::RecordReferralService.new(message: self).perform
  end
end
