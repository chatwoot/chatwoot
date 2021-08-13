# == Schema Information
#
# Table name: working_hours
#
#  id             :bigint           not null, primary key
#  close_hour     :integer
#  close_minutes  :integer
#  closed_all_day :boolean          default(FALSE)
#  day_of_week    :integer          not null
#  open_hour      :integer
#  open_minutes   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint
#  inbox_id       :bigint
#
# Indexes
#
#  index_working_hours_on_account_id  (account_id)
#  index_working_hours_on_inbox_id    (inbox_id)
#
class WorkingHour < ApplicationRecord
  belongs_to :inbox

  before_save :assign_account

  validates :open_hour,     presence: true, unless: :closed_all_day?
  validates :open_minutes,  presence: true, unless: :closed_all_day?
  validates :close_hour,    presence: true, unless: :closed_all_day?
  validates :close_minutes, presence: true, unless: :closed_all_day?

  validates :open_hour,     inclusion: 0..23, unless: :closed_all_day?
  validates :close_hour,    inclusion: 0..23, unless: :closed_all_day?
  validates :open_minutes,  inclusion: 0..59, unless: :closed_all_day?
  validates :close_minutes, inclusion: 0..59, unless: :closed_all_day?

  validate :close_after_open, unless: :closed_all_day?

  def self.today
    find_by(day_of_week: Date.current.wday)
  end

  def open_at?(time)
    return false if closed_all_day?

    time.hour >= open_hour &&
      time.min  >= open_minutes &&
      time.hour <= close_hour &&
      time.min  <= close_minutes
  end

  def open_now?
    inbox_time = Time.zone.now.in_time_zone(inbox.timezone)
    open_at?(inbox_time)
  end

  def closed_now?
    !open_now?
  end

  private

  def assign_account
    self.account_id = inbox.account_id
  end

  def close_after_open
    return unless open_hour.hours + open_minutes.minutes >= close_hour.hours + close_minutes.minutes

    errors.add(:close_hour, 'Closing time cannot be before opening time')
  end
end
