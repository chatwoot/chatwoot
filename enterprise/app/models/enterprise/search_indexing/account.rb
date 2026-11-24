module Enterprise::SearchIndexing::Account
  extend ActiveSupport::Concern

  included do
    before_save :clear_conversation_search_verification, if: :will_save_change_to_feature_flags_ext_1?
  end

  private

  def clear_conversation_search_verification
    return if feature_enabled?('advanced_search_conversations')

    self.internal_attributes = internal_attributes.except(::SearchIndexing::IndexVerification::KEY)
  end
end
