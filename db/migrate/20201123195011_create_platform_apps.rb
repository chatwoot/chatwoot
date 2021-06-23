class CreatePlatformApps < ActiveRecord::Migration[6.0]
  def change
    create_table :platform_apps do |t|
      t.string :name, null: false
      t.integer :type, null: false, default: 0
      t
        .t.timestamps
    end
  end
end
