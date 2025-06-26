class Zalo::CallbackController < ApplicationController
  def new
    auth_params = Zalo::GenerateChallengeService.new.perform
    auth_params.merge!({
                         redirect_uri: connect_zalo_callback_index_url(account_id: params[:account_id])
                       })
    redirect_to "https://oauth.zaloapp.com/v4/oa/permission?#{auth_params.to_query}", allow_other_host: true
  end

  def connect
    inbox = Zalo::CreateInboxService.new(permitted_params).perform
    redirect_to app_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
  rescue Zalo::CreateInboxService::Error => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to zalo_app_redirect_url(error: e.message)
  end

  private

  def zalo_app_redirect_url(error: nil)
    app_new_zalo_inbox_url(account_id: account.id, error: error)
  end

  def account
    @account ||= Account.find(permitted_params[:account_id])
  end

  def permitted_params
    @permitted_params ||= params.permit(:code, :account_id, :oa_id, :state, :code_challenge)
  end

  def create_inbox
    data = {
      oa_id: permitted_params[:oa_id],
      account_id: permitted_params[:account_id].to_i,
      auth_code: permitted_params[:code]
    }
    # Shopee::CreateInboxService.new(data).perform
  end
end
