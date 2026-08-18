class Api::V1::Accounts::Integrations::PathorsController < Api::V1::Accounts::Integrations::BaseController
  before_action :check_authorization
  before_action :fetch_pathors_records

  # Disconnecting is a two-sided operation. Pathors provisioned the agent bot
  # and issued the tokens, so it is told first — best effort, because a Pathors
  # outage must never leave the account stuck with an integration it cannot
  # remove. The local records go last, in one transaction.
  #
  # Destroying the agent bot keeps history: its inbox assignments cascade away,
  # while the messages and conversations it produced are only detached from it.
  def destroy
    return head :not_found if @hook.blank? && @agent_bot.blank?

    notify_pathors
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

  # Delivered through the agent bot webhook path, so the payload carries the
  # same signature headers Pathors already verifies with the bot's secret.
  def notify_pathors
    return if @agent_bot.blank?

    Webhooks::Trigger.execute(
      @agent_bot.outgoing_url,
      { event: 'integration.disconnected', account_id: Current.account.id },
      :agent_bot_webhook,
      secret: @agent_bot.secret
    )
  rescue StandardError => e
    Rails.logger.error("Failed to notify Pathors about the disconnect: #{e.message}")
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
