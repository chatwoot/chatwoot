class AddShowOnSidebarToDashboardApps < ActiveRecord::Migration[7.0]
  def change
    add_column :dashboard_apps, :show_on_sidebar, :boolean, default: false
  end
end
