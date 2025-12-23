# frozen_string_literal: true

class Api::V1::EmbedTokensController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization
  before_action :fetch_embed_token, only: [:show, :revoke]

  def index
    @embed_tokens = Current.account.embed_tokens
                             .includes(:user, :inbox, :created_by)
                             .order(created_at: :desc)
  end

  def show
    # Already fetched in before_action
  end

  def create
    user = Current.account.users.find(params[:user_id])
    inbox = params[:inbox_id].present? ? Current.account.inboxes.find(params[:inbox_id]) : nil

    result = EmbedTokenService.generate(
      user: user,
      account: Current.account,
      inbox: inbox,
      created_by: current_user,
      note: params[:note]
    )

    @embed_token = result[:embed_token]
    @embed_url = result[:embed_url]
    render json: {
      embed_token: @embed_token.as_json(only: [:id, :jti, :user_id, :account_id, :inbox_id, :created_at, :note]),
      embed_url: @embed_url
    }
  end

  def revoke
    EmbedTokenService.revoke(@embed_token)
    head :ok
  end

  private

  def fetch_embed_token
    @embed_token = Current.account.embed_tokens.find(params[:id])
  end
end

