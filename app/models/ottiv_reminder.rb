# == Schema Information
#
# Table name: ottiv_reminders
#
#  id                       :bigint           not null, primary key
#  ottiv_calendar_item_id   :bigint           not null
#  notify_at                :datetime         not null
#  channel                  :integer          default(0), not null
#  sent                     :boolean          default(false), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class OttivReminder < ApplicationRecord
  belongs_to :ottiv_calendar_item

  enum channel: { in_app: 0, push: 1, email: 2 }

  validates :notify_at, presence: true
  validates :ottiv_calendar_item_id, presence: true

  scope :pending, -> { where(sent: false).where('notify_at <= ?', Time.current) }
  scope :sent, -> { where(sent: true) }
  scope :by_channel, ->(channel) { where(channel: channel) }

  def mark_as_sent!
    update!(sent: true)
  end
end

