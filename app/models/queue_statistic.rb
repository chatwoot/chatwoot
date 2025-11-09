# == Schema Information
#
# Table name: queue_statistics
#
#  id                        :bigint           not null, primary key
#  average_wait_time_seconds :integer          default(0), not null
#  date                      :date             not null
#  max_wait_time_seconds     :integer          default(0), not null
#  total_assigned            :integer          default(0), not null
#  total_left                :integer          default(0), not null
#  total_queued              :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :bigint           not null
#
# Indexes
#
#  index_queue_statistics_on_account_id           (account_id)
#  index_queue_statistics_on_account_id_and_date  (account_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class QueueStatistic < ApplicationRecord
  belongs_to :account

  validates :date, uniqueness: { scope: :account_id }
  validates :total_queued, :total_assigned, :total_left, :average_wait_time_seconds, :max_wait_time_seconds,
            presence: true, numericality: { greater_than_or_equal_to: 0 }

  def self.update_statistics_for(account_id, wait_time_seconds:, assigned: false, left: false)
    stat = find_or_initialize_by(account_id: account_id, date: Date.current)
    stat.total_queued += 1
    stat.total_assigned += 1 if assigned
    stat.total_left += 1 if left

    if assigned && wait_time_seconds.positive?
      total_wait_time = (stat.average_wait_time_seconds * (stat.total_assigned - 1)) + wait_time_seconds
      stat.average_wait_time_seconds = (total_wait_time / stat.total_assigned).to_i
      stat.max_wait_time_seconds = [stat.max_wait_time_seconds, wait_time_seconds].max
    end

    stat.save!
  end
end
