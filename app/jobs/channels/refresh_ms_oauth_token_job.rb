# refer: https://gitlab.com/gitlab-org/ruby/gems/gitlab-mail_room/-/blob/master/lib/mail_room/microsoft_graph/connection.rb
# refer: https://github.com/microsoftgraph/msgraph-sample-rubyrailsapp/tree/b4a6869fe4a438cde42b161196484a929f1bee46

class Channels::RefreshMsOauthTokenJob < ApplicationJob
  queue_as :low

  def perform
    Channel::Email.where(provider: 'microsoft').each do |channel|
      # refresh the token here, with microsoft offline_access scope
      provider_config = channel.provider_config || {}

      refresh_tokens(channel, provider_config.with_indifferent_access) if provider_config[:refresh_token].present?
    end
  end

  # if the token is not expired yet then skip the refresh token step
  def access_token(channel, provider_config)
    expiry = DateTime.parse(provider_config[:expires_on]) - 5.minutes

    if Time.current > expiry
      # Token expired, refresh
      new_hash = refresh_tokens channel, provider_config
      new_hash[:access_token]
    else
      provider_config[:access_token]
    end
  end

  # <RefreshTokensSnippet>
  def refresh_tokens(channel, token_hash)
    oauth_strategy = OmniAuth::Strategies::MicrosoftGraphAuth.new(
      nil, ENV.fetch('AZURE_APP_ID', nil), ENV.fetch('AZURE_APP_SECRET', nil)
    )

    token = OAuth2::AccessToken.new(
      oauth_strategy.client, token_hash['access_token'],
      refresh_token: token_hash['refresh_token']
    )

    # Refresh the tokens
    new_tokens = token.refresh!.to_hash.slice(:access_token, :refresh_token, :expires_on)

    update_channel_provider_config(channel, new_tokens)
    channel.provider_config
  end
  # </RefreshTokensSnippet>

  def update_channel_provider_config(channel, new_tokens)
    new_tokens = new_tokens.with_indifferent_access
    channel.provider_config = {
      access_token: new_tokens.delete(:access_token),
      refresh_token: new_tokens.delete(:refresh_token),
      expires_on: new_tokens.delete(:expires_on)
    }
    channel.save!
  end
end
