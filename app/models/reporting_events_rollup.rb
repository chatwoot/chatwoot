# == Schema Information
#
# Table name: reporting_events_rollups
#
#  id                       :bigint           not null, primary key
#  count                    :bigint           default(0), not null
#  date                     :date             not null
#  dimension_type           :string           not null
#  metric                   :string           not null
#  sum_value                :float            default(0.0), not null
#  sum_value_business_hours :float            default(0.0), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :integer          not null
#  dimension_id             :bigint           not null
#
# Indexes
#
#  index_rollup_summary     (account_id,dimension_type,date)
#  index_rollup_timeseries  (account_id,metric,date)
#  index_rollup_unique_key  (account_id,date,dimension_type,dimension_id,metric) UNIQUE
#

class ReportingEventsRollup < ApplicationRecord
  belongs_to :account

  # Store string values directly in the database for better readability and debugging
  enum :dimension_type, %w[account agent inbox team].index_by(&:itself)
  enum :metric, %w[
    resolutions_count
    first_response
    resolution_time
    reply_time
    bot_resolutions_count
    bot_handoffs_count
  ].index_by(&:itself)

  validates :account_id, presence: true
  validates :date, presence: true
  validates :dimension_type, presence: true
  validates :dimension_id, presence: true
  validates :metric, presence: true
  validates :count, numericality: { greater_than_or_equal_to: 0 }

  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :for_dimension, ->(type, id) { where(dimension_type: type, dimension_id: id) }
  scope :for_metric, ->(metric) { where(metric: metric) }
end
