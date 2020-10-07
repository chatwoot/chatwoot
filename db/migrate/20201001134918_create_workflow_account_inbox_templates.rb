class CreateWorkflowAccountInboxTemplates < ActiveRecord::Migration[6.0]
  def change
    create_table :workflow_account_inbox_templates do |t|
      t.references :workflow_account_template, null: false, index: { name: 'account_template_with_workflow_account_template_inbox' }
      t.references :inbox, null: false, index: { name: 'inbox_with_workflow_account_template_inbox' }
      t.timestamps
    end
  end
end
