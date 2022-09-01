# This controller expects you to use the URLs /saml/init and /saml/consume in your OneLogin application.
class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:consume]

  def init
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(saml_settings))
  end

  def consume
    response          = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    response.settings = saml_settings

    # We validate the SAML Response and check if the user already exists in the system
    if response.is_valid?
       # authorize_success, log the user
       session[:userid] = response.nameid
       session[:attributes] = response.attributes
    else
      authorize_failure  # This method shows an error message
      # List of errors is available in response.errors array
    end
  end

  private

  def saml_settings
    settings = OneLogin::RubySaml::Settings.new

    settings.assertion_consumer_service_url = "http://#{request.host}/saml/consume"
    settings.sp_entity_id                   = "http://#{request.host}/saml/metadata"
    settings.idp_entity_id                  = "https://app.onelogin.com/saml/metadata/1835014"
    settings.idp_sso_target_url            = "https://app.onelogin.com/trust/saml2/http-post/sso/1835014"
    settings.idp_slo_target_url            = "https://app.onelogin.com/trust/saml2/http-redirect/slo/1835014"
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

    # Optional for most SAML IdPs
    settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
    # or as an array
    settings.authn_context = [
      "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport",
      "urn:oasis:names:tc:SAML:2.0:ac:classes:Password"
    ]

    # Optional bindings (defaults to Redirect for logout POST for ACS)
    settings.single_logout_service_binding      = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" # or :post, :redirect
    settings.assertion_consumer_service_binding = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" # or :post, :redirect

    settings
  end
end
