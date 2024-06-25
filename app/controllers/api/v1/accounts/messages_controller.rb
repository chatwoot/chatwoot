class Api::V1::Accounts::MessagesController < Api::V1::Accounts::BaseController
  include Sift
  include DateRangeHelper

  before_action :set_messages, only: [:index]
  before_action :set_current_page, only: [:index]

  def index; end

  private

  def set_messages
    base_query = Current.account.messages.includes(:inbox, :conversation)
    @messages = filtrate(base_query).filter_by_created_at(range)
                                    .filter_by_inbox(params[:inbox_id])
                                    .filter_by_team(params[:team_id])
                                    .filter_by_label(params[:label])
                                    .order(created_at: :desc)
  end

  def current_page_messages
    @messages = @messages.page(@current_page).per(RESULTS_PER_PAGE) if params[:page].present?
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
