class Api::V1::Accounts::Integrations::PathorsController < Api::V1::Accounts::Integrations::BaseController
  before_action :check_authorization
  before_action :fetch_pathors_records

  # Disconnecting is a two-sided operation. Pathors provisioned the agent bot
  # and issued the tokens, so both are retired on its side too — best effort,
  # because a Pathors outage must never leave the account stuck with an
  # integration it cannot remove. The local records go last, in one transaction.
  #
  # The disconnect notification is not sent from here: it hangs off the agent
  # bot's own destroy (Pathors::BotDisconnectNotifiable), so it fires for every
  # route that removes the bot rather than only for this one. Without a bot
  # there is no callback URL to notify, so a hook-only disconnect stays silent
  # either way.
  #
  # Destroying the agent bot keeps history: its inbox assignments cascade away,
  # while the messages and conversations it produced are only detached from it.
  def destroy
    return head :not_found if @hook.blank? && @agent_bot.blank?

    revoke_pathors_token

    ActiveRecord::Base.transaction do
      @hook&.destroy!
      @agent_bot&.destroy!
    end

    render json: {}
  end

  private

  def fetch_pathors_records
    @hook = Current.account.hooks.find_by(app_id: 'pathors')
    @agent_bot = Current.account.agent_bots.find_by(['outgoing_url LIKE ?', "%#{Integrations::App::PATHORS_CALLBACK_URL_FRAGMENT}%"])
  end

  # RFC 7009 revocation, mirroring how the Linear integration retires its grant.
  def revoke_pathors_token
    return if @hook.blank?

    refresh_token = @hook.settings.to_h['refresh_token']
    token = refresh_token.presence || @hook.access_token
    return if token.blank?

    HTTParty.post(
      "#{GlobalConfigService.load('PATHORS_API_URL', 'https://api.pathors.com')}/oauth/revoke",
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
      body: {
        token: token,
        token_type_hint: refresh_token.present? ? 'refresh_token' : 'access_token',
        client_id: GlobalConfigService.load('PATHORS_OAUTH_CLIENT_ID', nil),
        client_secret: GlobalConfigService.load('PATHORS_OAUTH_CLIENT_SECRET', nil)
      },
      timeout: 5
    )
  rescue StandardError => e
    Rails.logger.error("Failed to revoke the Pathors token: #{e.message}")
  end
end
