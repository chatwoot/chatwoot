class Api::V1::Accounts::ChatStatusItemsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization

  def index
    @chat_status_items = Current.account.chat_status_items
  end

  def show; end

  def create
    @chat_status_item = Current.account.chat_status_items.create!(permitted_params)
  end

  def permitted_params
    params.require(:chat_status_item).permit(:name, :custom)
  end
end
