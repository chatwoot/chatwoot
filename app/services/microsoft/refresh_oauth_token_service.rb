# refer: https://gitlab.com/gitlab-org/ruby/gems/gitlab-mail_room/-/blob/master/lib/mail_room/microsoft_graph/connection.rb
# refer: https://github.com/microsoftgraph/msgraph-sample-rubyrailsapp/tree/b4a6869fe4a438cde42b161196484a929f1bee46
# https://learn.microsoft.com/en-us/azure/active-directory/develop/active-directory-configurable-token-lifetimes

require 'microsoft_graph_auth'

class Microsoft::RefreshOauthTokenService
  # if the token is not expired yet then skip the refresh token step
  def access_token(channel, provider_config)
    if Time.current.utc >= expires_on(provider_config['expires_on'])
      # Token expired, refresh
      new_hash = refresh_tokens channel, provider_config
      new_hash[:access_token]
    else
      provider_config[:access_token]
    end
  end

  def expires_on(expiry)
    expiry.presence ? DateTime.parse(expiry) - 5.minutes : Time.current.utc
  end

  # <RefreshTokensSnippet>
  def refresh_tokens(channel, token_hash)
    oauth_strategy = ::MicrosoftGraphAuth.new(
      nil, ENV.fetch('AZURE_APP_ID', nil), ENV.fetch('AZURE_APP_SECRET', nil)
    )

    token = OAuth2::AccessToken.new(
      oauth_strategy.client, token_hash['access_token'],
      refresh_token: token_hash['refresh_token']
    )

    # Refresh the tokens
    new_tokens = token.refresh!.to_hash.slice(:access_token, :refresh_token, :expires_at)

    update_channel_provider_config(channel, new_tokens)
    channel.provider_config
  end
  # </RefreshTokensSnippet>

  def update_channel_provider_config(channel, new_tokens)
    new_tokens = new_tokens.with_indifferent_access
    channel.provider_config = {
      access_token: new_tokens.delete(:access_token),
      refresh_token: new_tokens.delete(:refresh_token),
      expires_on: Time.at(new_tokens.delete(:expires_at)).utc.to_s
    }
    channel.save!
  end
end
