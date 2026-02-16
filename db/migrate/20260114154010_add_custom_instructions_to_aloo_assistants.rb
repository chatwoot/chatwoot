class AddCustomInstructionsToAlooAssistants < ActiveRecord::Migration[7.1]
  def change
    add_column :aloo_assistants, :custom_instructions, :text
  end
end
