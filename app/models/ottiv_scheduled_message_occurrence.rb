# == Schema Information
#
# Table name: ottiv_scheduled_message_occurrences
#
#  id                          :bigint           not null, primary key
#  ottiv_scheduled_message_id  :bigint           not null
#  sent_at                     :datetime
#  status                      :integer          default(0), not null
#  error_message               :text
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#

class OttivScheduledMessageOccurrence < ApplicationRecord
  belongs_to :ottiv_scheduled_message

  enum status: { pending: 0, sent: 1, failed: 2 }

  validates :ottiv_scheduled_message_id, presence: true

  scope :successful, -> { where(status: :sent) }
  scope :failed, -> { where(status: :failed) }
  scope :recent, -> { order(created_at: :desc).limit(10) }
end

