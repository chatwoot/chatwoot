class RemoveSettingsFlagsFromAccount < ActiveRecord::Migration[6.1]
  def up
    change_table :accounts do |t|
      t.remove :settings_flags
    end
  end

  def down
    change_table :accounts do |t|
      t.integer :settings_flags, default: 0, null: false
    end
  end
end
