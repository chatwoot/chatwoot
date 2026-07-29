class Shopify::UninstallationService
  def initialize(hook:, occurred_at: nil)
    @hook = hook
    @account = hook.account
    @occurred_at = occurred_at
  end

  def perform
    failure = nil
    outcome = :stale
    hook.with_lock do
      next if stale_event?

      begin
        uninstall
        outcome = :uninstalled
      rescue StandardError => e
        failure = e
      end
    end
    raise failure if failure

    outcome
  end

  private

  attr_reader :account, :hook, :occurred_at

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
