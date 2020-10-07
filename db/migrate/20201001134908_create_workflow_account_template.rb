class CreateWorkflowAccountTemplate < ActiveRecord::Migration[6.0]
  def change
    create_table :workflow_account_templates do |t|
      t.string :template_id, null: false
      t.references :account, index: true, null: false
      t.jsonb :config, null: false, default: '{}'
      t.timestamps
    end
  end
end
