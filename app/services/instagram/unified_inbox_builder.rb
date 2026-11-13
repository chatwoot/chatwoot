class Instagram::UnifiedInboxBuilder
  def initialize(account:, token_response:, instagram_account:, configuration_id:)
    @account = account
    @token_response = token_response
    @instagram_account = instagram_account
    @configuration_id = configuration_id
  end

  def perform
    channel = @account.instagram_channels.find_or_initialize_by(instagram_id: @instagram_account.fetch('id'))
    already_exists = channel.persisted?
    channel.assign_attributes(channel_attributes)
    channel.validate!
    # Subscribe before writing: a denied subscription must not create a working-looking inbox.
    channel.subscribe
    ActiveRecord::Base.transaction do
      channel.save!
      @account.inboxes.create!(channel: channel, name: @instagram_account.fetch('username')) unless already_exists
      channel.reauthorized!
    end
    [channel.inbox, already_exists]
  end

  private

  def channel_attributes
    expires_in = @token_response['expires_in']
    {
      auth_type: 'unified_login',
      access_token: @token_response.fetch('access_token'),
      expires_at: expires_in&.positive? ? Time.current + expires_in.seconds : nil,
      configuration_id: @configuration_id,
      provider_name: @instagram_account.fetch('username')
    }
  end
end
