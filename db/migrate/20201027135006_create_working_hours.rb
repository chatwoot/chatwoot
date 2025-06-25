class CreateWorkingHours < ActiveRecord::Migration[6.0]
  def change
    create_table :working_hours do |t|
      t.belongs_to :inbox
      t.belongs_to :account

      t.integer :day_of_week, null: false
      t.boolean :closed_all_day, default: false
      t.integer :open_hour
      t.integer :open_minutes
      t.integer :close_hour
      t.integer :close_minutes

      t.timestamps
    end

    add_column :accounts, :timezone, :string, default: 'UTC'

    change_table :inboxes, bulk: true do |t|
      t.boolean :working_hours_enabled, default: false
      t.string :out_of_office_message
    end

    Inbox.where.not(id: WorkingHour.select(:inbox_id)).each do |inbox|
      create_working_hours_for_inbox(inbox)
    end
  end

  private

  def create_working_hours_for_inbox(inbox)
    inbox.working_hours.create!(day_of_week: 1, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    inbox.working_hours.create!(day_of_week: 2, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    inbox.working_hours.create!(day_of_week: 3, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    inbox.working_hours.create!(day_of_week: 4, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    inbox.working_hours.create!(day_of_week: 5, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    inbox.working_hours.create!(day_of_week: 6, closed_all_day: true)
    inbox.working_hours.create!(day_of_week: 7, closed_all_day: true)
  end
end
