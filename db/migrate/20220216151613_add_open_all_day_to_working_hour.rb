class AddOpenAllDayToWorkingHour < ActiveRecord::Migration[6.1]
  def change
    add_column :working_hours, :open_all_day, :boolean, default: false
  end
end
