# == Schema Information
#
# Table name: calendar_connection_calendars
#
#  id                     :bigint           not null, primary key
#  external_id            :string           not null
#  is_enabled             :boolean          default(FALSE), not null
#  is_primary             :boolean          default(FALSE), not null
#  summary                :string           default(""), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  calendar_connection_id :bigint           not null
#
class CalendarConnectionCalendar < ApplicationRecord
  belongs_to :account
  belongs_to :calendar_connection

  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :calendar_connection_id }
  validates :hour_start, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 22 }
  validates :hour_end, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 23 }
  validate :hour_range_order

  scope :enabled, -> { where(is_enabled: true) }

  private

  def hour_range_order
    return if hour_end.nil? || hour_start.nil?
    return if hour_end > hour_start

    errors.add(:hour_end, :greater_than, count: hour_start)
  end
end
