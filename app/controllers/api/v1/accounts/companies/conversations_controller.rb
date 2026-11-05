class Api::V1::Accounts::Companies::ConversationsController < Api::V1::Accounts::Companies::BaseController
  before_action :authorize_company_read!
  before_action :set_counts

  def index
    @conversations = Conversations::SortService.apply(company_conversations, params[:sort_by])
                                               .includes(:assignee, :contact, :inbox, :taggings)
                                               .preload(ai_assignee: { avatar_attachment: [:blob] })
                                               .page(params[:page] || 1)
  end

  def filter
    @conversations = Companies::ConversationFilterService.new(
      params.permit!, Current.user, Current.account, company: @company
    ).perform[:conversations]
    render :index
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  private

  def company_conversations
    @company_conversations ||= Conversations::PermissionFilterService.new(
      Current.account.conversations.where(contact_id: @company.contacts.select(:id)),
      Current.user,
      Current.account
    ).perform
  end

  def set_counts
    @all_count = company_conversations.count
    @open_count = company_conversations.open.count
  end
end
