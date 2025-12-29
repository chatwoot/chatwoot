class Api::V1::Accounts::InboxFaqCategoriesController < Api::V1::Accounts::BaseController
  before_action :inbox
  before_action :check_authorization

  def index
    @faq_categories = inbox.faq_categories.includes(:children)
    render json: { data: @faq_categories.as_json(only: %i[id name]) }
  end

  def create
    inbox.faq_category_ids = params[:faq_category_ids] || []
    inbox.save!
    render json: { data: inbox.faq_categories.as_json(only: %i[id name]) }
  end

  private

  def inbox
    @inbox ||= Current.account.inboxes.find(params[:inbox_id])
  end
end
