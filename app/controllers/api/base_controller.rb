class Api::BaseController < ApplicationController
  include AccessTokenAuthHelper
  # POST-shaped endpoints that are semantically reads and should be reachable
  # with a read-only token. Keep this list minimal; expand only when a clear
  # read-with-complex-body use case appears.
  READ_ONLY_POST_ALLOWLIST = %w[
    api/v1/accounts/conversations#filter
    api/v1/accounts/contacts#filter
  ].freeze

  respond_to :json
  before_action :authenticate_access_token!, if: :authenticate_by_access_token?
  before_action :validate_bot_access_token!, if: :authenticate_by_access_token?
  before_action :authenticate_user!, unless: :authenticate_by_access_token?
  before_action :enforce_read_only_token_scope

  private

  def authenticate_by_access_token?
    request.headers[:api_access_token].present? || request.headers[:HTTP_API_ACCESS_TOKEN].present?
  end

  def enforce_read_only_token_scope
    return unless @access_token&.scope == 'read_only'
    return if request.get? || request.head? || request.options?
    return if READ_ONLY_POST_ALLOWLIST.include?("#{params[:controller]}##{params[:action]}")

    render json: { error: 'This access token is read-only and cannot perform write operations.' },
           status: :forbidden
  end

  def check_authorization(model = nil)
    model ||= controller_name.classify.constantize

    authorize(model)
  end

  def check_admin_authorization?
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
