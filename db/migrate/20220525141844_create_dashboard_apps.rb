class CreateDashboardApps < ActiveRecord::Migration[6.1]
  def change
    create_table :dashboard_apps do |t|
      t.string :title, null: false
      t.jsonb :content, default: []
      t.references :account, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
