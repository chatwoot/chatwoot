class AddShowOnSidebarToDashboardApps < ActiveRecord::Migration[7.1]
  def change
    add_column :dashboard_apps, :show_on_sidebar, :boolean, default: false, null: false
  end
end
