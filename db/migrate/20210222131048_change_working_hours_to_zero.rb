class ChangeWorkingHoursToZero < ActiveRecord::Migration[6.0]
  # rubocop:disable Rails/SkipsModelValidations
  def up
    WorkingHour.where(day_of_week: 7).update_all(day_of_week: 0)
  end

  def down
    WorkingHour.where(day_of_week: 0).update_all(day_of_week: 7)
  end
  # rubocop:enable Rails/SkipsModelValidations
end
