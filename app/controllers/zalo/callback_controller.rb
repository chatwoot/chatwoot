class Zalo::CallbackController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def create
    code = params[:code]
    account_id = params[:state]
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    redirect_to "#{frontend_url}/app/accounts/#{account_id}/settings/inboxes/new/zalo?code=#{code}"
  end
end
