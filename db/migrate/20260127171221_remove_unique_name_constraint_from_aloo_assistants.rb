# frozen_string_literal: true

class RemoveUniqueNameConstraintFromAlooAssistants < ActiveRecord::Migration[7.1]
  def change
    remove_index :aloo_assistants, %i[account_id name], unique: true
    add_index :aloo_assistants, %i[account_id name]
  end
end
