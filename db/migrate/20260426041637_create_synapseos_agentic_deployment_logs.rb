class CreateSynapseosAgenticDeploymentLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :synapseos_agentic_deployment_logs do |t|
      t.string :slug, null: false
      t.integer :account_id
      t.integer :super_admin_id
      t.string :action, null: false
      t.string :status, null: false
      t.jsonb :payload
      t.jsonb :result_summary
      t.text :error_message

      t.datetime :created_at, null: false
    end

    add_index :synapseos_agentic_deployment_logs, :slug
    add_index :synapseos_agentic_deployment_logs, :account_id
    add_index :synapseos_agentic_deployment_logs, :action
  end
end
