class Api::V1::BaseController < ActionController::API
  include ApiTokenAuth
  before_action -> { ensure_api_token!(params[:account_id]) }
  skip_before_action :authenticate_user!, raise: false

  private
  attr_reader :current_account, :current_user
end
