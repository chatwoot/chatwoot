# frozen_string_literal: true

class CreateInboxAssignmentPolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_assignment_policies do |t|
      t.references :inbox, null: false, index: true
      t.references :assignment_policy, null: false, index: true

      t.timestamps
    end

    add_index :inbox_assignment_policies, :inbox_id, unique: true, name: 'unique_inbox_assignment_policy'
  end
end