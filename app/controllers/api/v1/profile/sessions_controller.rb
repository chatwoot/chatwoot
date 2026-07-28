class Api::V1::Profile::SessionsController < Api::BaseController
  before_action :set_session, only: [:destroy]

  def index
    @sessions = current_user.user_sessions.where(client_id: active_token_client_ids).order(last_activity_at: :desc)
    @current_client_id = request.headers['client']
  end

  def destroy
    if @session.current?(request.headers['client'])
      render json: { error: I18n.t('profile_settings.sessions.cannot_revoke_current') }, status: :unprocessable_entity
      return
    end

    revoke_token!(@session.client_id)
    @session.destroy!
    head :ok
  end

  private

  def set_session
    @session = current_user.user_sessions.find(params[:id])
  end

  def revoke_token!(client_id)
    tokens = current_user.tokens
    tokens.delete(client_id)
    current_user.update!(tokens: tokens)
  end

  def active_token_client_ids
    now = Time.current.to_i
    (current_user.tokens || {}).select { |_, v| v['expiry'].to_i > now }.keys
  end
end
