class Api::V1::Accounts::Conversations::UnreadCountsController < Api::V1::Accounts::BaseController
  before_action :ensure_unread_counts_enabled

  def index
    counts = ::Conversations::UnreadCounts::Counter.new(account: Current.account, user: Current.user).perform
    render json: { payload: counts }
  end

  private

  def ensure_unread_counts_enabled
    return if ::Conversations::UnreadCounts::Feature.enabled?(Current.account)

    render json: { error: I18n.t('errors.conversations.unread_counts.feature_not_enabled') }, status: :forbidden
  end
end
