class Integrations::Stripe::UninstallationService
  def initialize(event:)
    @event = event
  end

  def perform
    hooks.select(:account_id).distinct.pluck(:account_id).each do |account_id|
      Account.find(account_id).with_lock do
        hooks.where(account_id: account_id).lock.each do |hook|
          connected_at = hook.settings['connected_at']
          # Equal timestamps cannot distinguish an uninstall from a newer reconnection in the same second.
          next if connected_at.present? && @event.created <= Time.iso8601(connected_at).to_i

          hook.reauthorized!
          hook.destroy!
        end
      end
    end
  end

  private

  def hooks
    Integrations::Hook.where(app_id: 'stripe', reference_id: @event.account)
                      .where("COALESCE((settings->>'livemode')::boolean, false) = ?", @event.livemode)
  end
end
