class BackfillIntegrationModeOnSlackHooks < ActiveRecord::Migration[7.1]
  def up
    Integrations::Hook.where(app_id: 'slack').find_each do |hook|
      next if hook.settings&.key?('integration_mode')

      # update_column skips validations like ensure_feature_enabled, which would
      # fail for accounts that disabled the slack_integration feature after connecting.
      hook.update_column(:settings, (hook.settings || {}).merge('integration_mode' => 'two_way')) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    # no-op: a missing integration_mode already behaves as two_way
  end
end
