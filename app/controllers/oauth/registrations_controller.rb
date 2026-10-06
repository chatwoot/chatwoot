# Dynamic client registration, as defined in RFC 7591.
# Anyone can register, so every client is public and proves itself with PKCE instead of a secret.
class Oauth::RegistrationsController < ApplicationController
  GRANT_TYPES = %w[authorization_code refresh_token].freeze
  RESPONSE_TYPES = %w[code].freeze
  TOKEN_ENDPOINT_AUTH_METHOD = 'none'.freeze

  def create
    application = Doorkeeper::Application.new(
      name: registration_params[:client_name],
      redirect_uri: registration_params[:redirect_uris].to_a.join("\n"),
      scopes: registration_params[:scope].to_s,
      confidential: false
    )

    if application.save
      render json: client_metadata(application), status: :created
    else
      render json: registration_error(application), status: :bad_request
    end
  end

  private

  def registration_params
    params.permit(:client_name, :scope, redirect_uris: [])
  end

  def client_metadata(application)
    {
      client_id: application.uid,
      client_id_issued_at: application.created_at.to_i,
      client_name: application.name,
      redirect_uris: application.redirect_uri.split,
      scope: application.scopes.to_s,
      grant_types: GRANT_TYPES,
      response_types: RESPONSE_TYPES,
      token_endpoint_auth_method: TOKEN_ENDPOINT_AUTH_METHOD
    }
  end

  def registration_error(application)
    {
      error: application.errors.include?(:redirect_uri) ? 'invalid_redirect_uri' : 'invalid_client_metadata',
      error_description: application.errors.full_messages.to_sentence
    }
  end
end
