# frozen_string_literal: true

module OutOfOffisable
  extend ActiveSupport::Concern

  included do
    has_many :working_hours, dependent: :destroy
    after_create :create_default_working_hours
  end

  def out_of_office?
    working_hours_enabled? && working_hours.today.closed_now?
  end

  def working_now?
    !out_of_office?
  end

  private

  def create_default_working_hours
    working_hours.create!(day_of_week: 1, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    working_hours.create!(day_of_week: 2, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    working_hours.create!(day_of_week: 3, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    working_hours.create!(day_of_week: 4, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    working_hours.create!(day_of_week: 5, open_hour: 9, open_minutes: 0, close_hour: 17, close_minutes: 0)
    working_hours.create!(day_of_week: 6, closed_all_day: true)
    working_hours.create!(day_of_week: 7, closed_all_day: true)
  end
end
