class Internal::ValidateOpenaiHooksJob < ApplicationJob
  queue_as :low

  def perform(account: nil)
    scope = Integrations::Hook.where(app_id: 'openai', status: 'enabled')
    scope = scope.where(account_id: account.id) if account

    stats = { checked: 0, disabled: 0 }

    scope.find_each do |hook|
      stats[:checked] += 1
      next if Integrations::Openai::KeyValidator.valid?(hook.settings&.dig('api_key'))

      hook.disable
      stats[:disabled] += 1
      Rails.logger.warn("[openai-backfill] disabled hook_id=#{hook.id} account_id=#{hook.account_id}")
    end

    Rails.logger.info("[openai-backfill] completed #{stats.inspect}")
    stats
  end
end
