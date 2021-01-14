class CreatePlatformAppPermissibles < ActiveRecord::Migration[6.0]
  def change
    create_table :platform_app_permissibles do |t|
      t.references :platform_app, index: true, null: false
      t.references :permissible, null: false, polymorphic: true, index: { name: :index_platform_app_permissibles_on_permissibles }
      t.timestamps
    end

    add_index :platform_app_permissibles, [:platform_app_id, :permissible_id, :permissible_type], unique: true, name: 'unique_permissibles_index'
  end
end
