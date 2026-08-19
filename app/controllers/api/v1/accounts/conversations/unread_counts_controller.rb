class Api::V1::Accounts::Conversations::UnreadCountsController < Api::V1::Accounts::BaseController
  before_action :ensure_unread_counts_enabled

  def index
    counts = if filtered_unread_counts_enabled?
               instrumentation.summarize_request(account_id: Current.account.id) { unread_counts }
             else
               unread_counts
             end
    render json: { payload: counts }
  end

  private

  def unread_counts
    ::Conversations::UnreadCounts::Counter.new(account: Current.account, user: Current.user).perform
  end

  def filtered_unread_counts_enabled?
    Current.account.feature_enabled?(::Conversations::UnreadCounts::FilteredCounter::FEATURE_FLAG)
  end

  def instrumentation
    ::Conversations::UnreadCounts::FilteredCountInstrumentation
  end

  def ensure_unread_counts_enabled
    return if Current.account.feature_enabled?('conversation_unread_counts')

    render json: { error: I18n.t('errors.conversations.unread_counts.feature_not_enabled') }, status: :forbidden
  end
end
