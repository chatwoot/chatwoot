class Channels::RefreshMsOauthTokenJob < ApplicationJob
  queue_as :low

  def perform
    Channel::Email.all.each do |channel|
      # refresh the token here, offline access should work

      ms_oauth_token_hash = channel.ms_oauth_token_hash || {}

      refresh_tokens(channel, ms_oauth_token_hash) if ms_oauth_token_hash[:access_token].present?
    end
  end

  # if the token is not expired yet then skip the refresh token step
  def access_token(channel, ms_oauth_token_hash)
    expiry = Time.zone.at(ms_oauth_token_hash[:expires_at] - 300)

    if Time.zone.now > expiry
      # Token expired, refresh
      new_hash = refresh_tokens channel, ms_oauth_token_hash
      new_hash[:access_token]
    else
      ms_oauth_token_hash[:access_token]
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
    new_tokens = token.refresh!.to_hash.slice(:access_token, :refresh_token, :expires_at)

    update_channel_ms_oauth_tokens(channel, new_tokens)
    channel.ms_oauth_token_hash
  end
  # </RefreshTokensSnippet>

  def update_channel_ms_oauth_tokens(channel, new_tokens)
    new_tokens = new_tokens.with_indifferent_access
    channel.ms_oauth_token_hash = { access_token: new_tokens.delete(:access_token), refresh_token: new_tokens.delete(:refresh_token),
                                    expires_at: new_tokens.delete(:expires_at) }
    channel.save!
  end
end
