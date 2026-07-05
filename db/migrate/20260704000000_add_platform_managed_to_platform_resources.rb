# Fork: platform-managed resources (docs/fork/adr/0002). The system AI AgentBot,
# its account webhook, and the platform's automation account_user are
# infrastructure owned by the control plane, not tenant-billable resources.
# Flagged rows are excluded from Custom::EntitlementService quota counts.
class AddPlatformManagedToPlatformResources < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_bots, :platform_managed, :boolean, default: false, null: false
    add_column :webhooks, :platform_managed, :boolean, default: false, null: false
    add_column :account_users, :platform_managed, :boolean, default: false, null: false
  end
end
