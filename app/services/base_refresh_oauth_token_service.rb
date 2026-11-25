class BaseRefreshOauthTokenService
  pattr_initialize [:channel!]

  # Additional references: https://gitlab.com/gitlab-org/ruby/gems/gitlab-mail_room/-/blob/master/lib/mail_room/microsoft_graph/connection.rb
  def access_token
    return provider_config[:access_token] unless access_token_expired?

    refreshed_tokens = refresh_tokens
    refreshed_tokens[:access_token]
  end

  def access_token_expired?
    expiry = provider_config[:expires_on]

    return true if expiry.blank?

    # Adding a 5 minute window to expiry check to avoid any race
    # conditions during the fetch operation. This would assure that the
    # tokens are updated when we fetch the emails.
    Time.current.utc >= DateTime.parse(expiry) - 5.minutes
  end

  # Refresh the access tokens using the refresh token
  # Refer: https://github.com/microsoftgraph/msgraph-sample-rubyrailsapp/tree/b4a6869fe4a438cde42b161196484a929f1bee46
  def refresh_tokens
    spent_refresh_token = provider_config[:refresh_token]
    raise 'A refresh_token is not available' if spent_refresh_token.blank?

    oauth_strategy = build_oauth_strategy
    token_service = build_token_service(oauth_strategy)

    new_tokens = token_service.refresh!.to_hash.slice(:access_token, :refresh_token, :expires_at)

    update_channel_provider_config(new_tokens, spent_refresh_token: spent_refresh_token)
    # Re-read, and replace the memo with it. Two things depend on this being the row rather than the
    # copy this object started with: the caller reads `[:access_token]` off what comes back, and when
    # the write did not land, what comes back has to be the token set that did. `with_indifferent_access`
    # because the column is a jsonb read back with String keys, and every reader here asks with symbols;
    # handing the raw hash up made `access_token` answer nil, which is what
    # `Imap::MicrosoftFetchEmailService` passes as the IMAP password.
    @provider_config = channel.reload.provider_config.with_indifferent_access
  end

  # The three keys the refresh owns, merged into the row rather than assigned over it. What used to
  # happen is that the whole column was replaced: anything else stored in `provider_config` was
  # erased on the first refresh, silently. Not hypothetical -- `Platform::Api::V1::EmailChannelMigrationsController`
  # writes this column from a payload that permits an open hash, so a migrated channel can hold keys
  # that nobody here knows about.
  #
  # The merge alone does not make two concurrent refreshes safe, and it never could: both exchanged
  # the same refresh token before either wrote, so the keys the loser writes are the keys the winner
  # already wrote and there is nothing to merge them with. A provider that rotates refresh tokens
  # invalidates the one it just replaced, so only one of the two pairs is live, and last writer wins
  # can leave the row holding the dead one. The channel then stops fetching until somebody reconnects
  # it by hand.
  #
  # So the write is conditional on the row still holding the refresh token this call spent. Losing is
  # not an error and does not raise: the other refresh already stored a live pair, the caller re-reads
  # and gets it. What losing must not be is silent, because the rotation this call spent is gone and
  # the provider has seen a token the row never held.
  def update_channel_provider_config(new_tokens, spent_refresh_token:)
    result = channel.swap_json_column!(
      :provider_config,
      expect: { refresh_token: spent_refresh_token },
      merge: {
        access_token: new_tokens[:access_token],
        refresh_token: new_tokens[:refresh_token],
        expires_on: Time.at(new_tokens[:expires_at]).utc.to_s
      }
    )

    return result unless result == :stale

    Rails.logger.warn("[OAUTH] Refresh for #{channel.class.name} #{channel.id} was not stored: the row no longer " \
                      'holds the refresh token this call spent, so another refresh rotated it first')
    result
  end

  private

  def build_oauth_strategy
    raise NotImplementedError
  end

  def provider_config
    @provider_config ||= channel.provider_config.with_indifferent_access
  end

  # Builds the token service using OAuth2
  def build_token_service(oauth_strategy)
    OAuth2::AccessToken.new(
      oauth_strategy.client,
      provider_config[:access_token],
      refresh_token: provider_config[:refresh_token]
    )
  end
end
