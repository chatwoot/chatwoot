# frozen_string_literal: true
module ApiTokenAuth
  extend ActiveSupport::Concern

  class InvalidAccessToken < StandardError; end

  included do
    rescue_from InvalidAccessToken do
      render json: { error: 'Invalid Access Token' }, status: :unauthorized
    end
  end

  # account_id is the path param (e.g., /accounts/:account_id/…)
  def ensure_api_token!(account_id)
    raw = extract_token_from_request
    raise InvalidAccessToken if raw.blank?

    # Try common storage patterns: plain, SHA256 hex, or bcrypt-style
    token_rec =
      AccessToken.find_by(token: raw) ||
      AccessToken.find_by(token: Digest::SHA256.hexdigest(raw)) ||
      lookup_bcrypt_token(raw)

    raise InvalidAccessToken if token_rec.blank?

    owner = token_rec.owner
    @current_user =
      case owner
      when User          then owner
      when AccountUser   then owner.user
      else
        raise InvalidAccessToken
      end

    @current_account =
      if account_id.present?
        Account.find_by(id: account_id)
      else
        owner.is_a?(AccountUser) ? owner.account : @current_user.accounts.first
      end

    raise InvalidAccessToken if @current_account.blank?
    raise InvalidAccessToken unless AccountUser.exists?(account: @current_account, user: @current_user)
  end

  private

  # Accepts multiple ways of sending the token
  def extract_token_from_request
    req = request
    req.headers['Api-Access-Token'].presence ||
      req.headers['api_access_token'].presence ||
      req.get_header('HTTP_API_ACCESS_TOKEN').presence ||
      params[:api_access_token].presence ||
      bearer_token(req)
  end

  def bearer_token(req)
    auth = req.headers['Authorization'].to_s
    scheme, token = auth.split(' ', 2)
    scheme&.casecmp('Bearer')&.zero? ? token : nil
  end

  # Slow-path bcrypt check (only runs if needed; OK for small token counts)
  def lookup_bcrypt_token(raw)
    bcryptable = AccessToken.where("token LIKE '$2a$%' OR token LIKE '$2b$%' OR token LIKE '$2y$%'")
    bcryptable.find { |t| BCrypt::Password.new(t.token) == raw }
  rescue LoadError
    nil
  end
end
