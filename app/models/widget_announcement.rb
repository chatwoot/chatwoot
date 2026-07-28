# == Schema Information
#
# Table name: widget_announcements
#
#  id         :bigint           not null, primary key
#  action_url :string
#  enabled    :boolean          default(TRUE), not null
#  ends_at    :datetime
#  level      :integer          default("info"), not null
#  message    :text
#  starts_at  :datetime
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  inbox_id   :bigint           not null
#
# Indexes
#
#  index_widget_announcements_on_account_id            (account_id)
#  index_widget_announcements_on_inbox_id              (inbox_id)
#  index_widget_announcements_on_inbox_id_and_enabled  (inbox_id,enabled)
#
class WidgetAnnouncement < ApplicationRecord
  belongs_to :account
  belongs_to :inbox

  enum level: { info: 0, warning: 1, critical: 2 }

  validates :title, presence: true
  validate :ends_after_start

  scope :active, lambda {
    now = Time.current
    where(enabled: true)
      .where('starts_at IS NULL OR starts_at <= ?', now)
      .where('ends_at IS NULL OR ends_at >= ?', now)
  }

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, 'must be after the start time')
  end
end
