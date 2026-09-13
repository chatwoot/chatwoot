class Api::V1::Accounts::Captain::AproposSessionsController < Api::V1::Accounts::BaseController
  before_action :ensure_access
  before_action :set_session, only: [:show, :update]

  rescue_from Captain::Apropos::Error do |error|
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def index
    render json: sessions.order(updated_at: :desc).limit(30).map { |session| session.public_payload.except(:trace) }
  end

  def show
    render json: @session.public_payload
  end

  def create
    session = sessions.create!
    session.enqueue!(params.require(:message))
    render json: session.public_payload, status: :accepted
  end

  def update
    @session.enqueue!(params.require(:message))
    render json: @session.public_payload, status: :accepted
  end

  private

  def ensure_access
    Captain::Apropos::Access.check!(Current.account, Current.user)
  rescue Captain::Apropos::Error => e
    render json: { error: e.message }, status: :forbidden
  end

  def sessions
    Captain::AproposSession.where(account: Current.account, user: Current.user)
  end

  def set_session
    @session = sessions.find(params[:id])
  end
end
