# Restore the Companies feature (dropped with enterprise edition).
class Api::V1::Accounts::Companies::ConversationsController < Api::V1::Accounts::BaseController
  before_action :company
  before_action :check_authorization

  RESULTS_PER_PAGE = 15

  def index
    conversation_ids = company.contacts.distinct.joins(:conversations).pluck('conversations.id')
    @conversations = Current.account.conversations.where(id: conversation_ids)
                         .order(last_activity_at: :desc)
                         .page(params[:page] || 1).per(RESULTS_PER_PAGE)
  end

  private

  def company
    @company ||= Current.account.companies.find(params[:company_id])
  end
end
