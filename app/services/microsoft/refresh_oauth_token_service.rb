# refer: https://gitlab.com/gitlab-org/ruby/gems/gitlab-mail_room/-/blob/master/lib/mail_room/microsoft_graph/connection.rb
# refer: https://github.com/microsoftgraph/msgraph-sample-rubyrailsapp/tree/b4a6869fe4a438cde42b161196484a929f1bee46
# https://learn.microsoft.com/en-us/azure/active-directory/develop/active-directory-configurable-token-lifetimes
class Microsoft::RefreshOauthTokenService
  pattr_initialize [:channel!]

  # if the token is not expired yet then skip the refresh token step
  def access_token
    provider_config = channel.provider_config.with_indifferent_access
    if Time.current.utc >= expires_on(provider_config['expires_on'])
      # Token expired, refresh
      new_hash = refresh_tokens
      new_hash[:access_token]
    else
      provider_config[:access_token]
    end
  end

  def expires_on(expiry)
    # we will give it a 5 minute gap for safety
    expiry.presence ? DateTime.parse(expiry) - 5.minutes : Time.current.utc
  end

  # <RefreshTokensSnippet>
  def refresh_tokens
    token_hash = channel.provider_config.with_indifferent_access
    oauth_strategy = ::MicrosoftGraphAuth.new(
      nil, ENV.fetch('AZURE_APP_ID', nil), ENV.fetch('AZURE_APP_SECRET', nil)
    )

    token_service = OAuth2::AccessToken.new(
      oauth_strategy.client, token_hash['access_token'],
      refresh_token: token_hash['refresh_token']
    )

    # Refresh the tokens
    new_tokens = token_service.refresh!.to_hash.slice(:access_token, :refresh_token, :expires_at)

    update_channel_provider_config(new_tokens)
    channel.provider_config
  end
  # </RefreshTokensSnippet>

  def update_channel_provider_config(new_tokens)
    new_tokens = new_tokens.with_indifferent_access
    channel.provider_config = {
      access_token: new_tokens[:access_token],
      refresh_token: new_tokens[:refresh_token],
      expires_on: Time.at(new_tokens[:expires_at]).utc.to_s
    }
    channel.save!
  end
end
