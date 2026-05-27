class Api::BaseController < ApplicationController
  include AccessTokenAuthHelper
  # POST-shaped endpoints that are semantically reads and should be reachable
  # with a read-only token. Keep this list minimal; expand only when a clear
  # read-with-complex-body use case appears.
  READ_ONLY_POST_ALLOWLIST = %w[
    api/v1/accounts/conversations#filter
    api/v1/accounts/contacts#filter
    api/v1/accounts/contact_inboxes#filter
  ].freeze

  # GET-shaped endpoints that mutate state and must be blocked for read-only
  # tokens despite the verb being "safe". Add any new write-on-GET endpoint
  # here when it ships.
  READ_ONLY_BLOCKED_GET_ACTIONS = %w[
    api/v1/accounts/callbacks#register_facebook_page
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
    return if read_only_token_action_allowed?

    render json: { error: 'This access token is read-only and cannot perform write operations.' },
           status: :forbidden
  end

  def read_only_token_action_allowed?
    action_key = "#{params[:controller]}##{params[:action]}"
    return READ_ONLY_POST_ALLOWLIST.include?(action_key) unless safe_http_method?

    READ_ONLY_BLOCKED_GET_ACTIONS.exclude?(action_key)
  end

  def safe_http_method?
    request.get? || request.head? || request.options?
  end

  def check_authorization(model = nil)
    model ||= controller_name.classify.constantize

    authorize(model)
  end

  def check_admin_authorization?
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
