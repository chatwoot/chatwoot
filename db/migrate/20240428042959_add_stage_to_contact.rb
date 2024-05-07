class AddStageToContact < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :stage_id, :integer
  end
end
