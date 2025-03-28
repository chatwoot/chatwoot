class Shopee::CallbackController < ApplicationController
  def show
    if permitted_params[:code] && permitted_params[:shop_id] && permitted_params[:account_id]
      inbox = create_inbox
      redirect_to app_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    else
      redirect_to shopee_app_redirect_url(error: 'Invalid parameters')
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to shopee_app_redirect_url(error: e.message)
  end

  private

  def shopee_app_redirect_url(error: nil)
    app_new_shopee_inbox_url(account_id: account.id, error: error)
  end

  def account
    @account ||= Account.find(permitted_params[:account_id])
  end

  def permitted_params
    @permitted_params ||= params.permit(:code, :shop_id, :account_id)
  end

  def create_inbox
    data = {
      account_id: permitted_params[:account_id].to_i,
      shop_id: permitted_params[:shop_id].to_i,
      auth_code: permitted_params[:code]
    }
    Shopee::CreateInboxService.new(data).perform
  end
end
