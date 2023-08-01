class UpdateDefaultStatusInHooks < ActiveRecord::Migration[7.0]
  def up
    change_column_default :integrations_hooks, :status, 1

    update_default_status
  end

  def down
    change_column_default :integrations_hooks, :status, 0
  end

  private

  def update_default_status
    Integrations::Hook.where(app_id: %w[dialogflow google_translate dyte]).all
  end
end
