# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# frozen_string_literal: true

# Refer: https://github.com/microsoftgraph/msgraph-sample-rubyrailsapp

require 'omniauth-oauth2'

# Implements an OmniAuth strategy to get a Microsoft Graph
# compatible token from Azure AD
class MicrosoftGraphAuth < OmniAuth::Strategies::OAuth2
  option :name, :microsoft_graph_auth

  DEFAULT_SCOPE = 'offline_access https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send'

  # Configure the Microsoft identity platform endpoints
  option :client_options,
         site: 'https://login.microsoftonline.com',
         authorize_url: '/common/oauth2/v2.0/authorize',
         token_url: '/common/oauth2/v2.0/token'

  option :pcke, true
  # Send the scope parameter during authorize
  option :authorize_options, [:scope]

  # Unique ID for the user is the id field
  uid { raw_info['id'] }

  # Get additional information after token is retrieved
  extra do
    {
      'raw_info' => raw_info
    }
  end

  def raw_info
    # Get user profile information from the /me endpoint
    @raw_info ||= access_token.get('https://graph.microsoft.com/v1.0/me?$select=displayName').parsed
  end

  def authorize_params
    super.tap do |params|
      params[:scope] = request.params['scope'] if request.params['scope']
      params[:scope] ||= DEFAULT_SCOPE
    end
  end

  # Override callback URL
  # OmniAuth by default passes the entire URL of the callback, including
  # query parameters. Azure fails validation because that doesn't match the
  # registered callback.
  def callback_url
    ENV.fetch('FRONTEND_URL', nil) + app_path
  end
end
