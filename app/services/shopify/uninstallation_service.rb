class Shopify::UninstallationService
  def initialize(hook:, occurred_at: nil, delete_hook: false)
    @hook = hook
    @account = hook.account
    @occurred_at = occurred_at
    @delete_hook = delete_hook
  end

  def perform
    failure = nil
    outcome = :stale
    account.with_lock do
      hook.with_lock do
        next if stale_event?

        begin
          Shopify::InstallationGeneration.advance!(account)
          uninstall
          hook.destroy! if delete_hook && hook.persisted?
          outcome = :uninstalled
        rescue StandardError => e
          failure = e
        end
      end
    end
    raise failure if failure

    outcome
  end

  private

  attr_reader :account, :hook, :occurred_at, :delete_hook

  def stale_event?
    connected_at = hook.settings['connected_at']
    return false if occurred_at.blank? || connected_at.blank?

    occurred_at < Time.iso8601(connected_at)
  end

  def uninstall
    hook.destroy!
  end
end

Shopify::UninstallationService.prepend_mod_with('Shopify::UninstallationService')
