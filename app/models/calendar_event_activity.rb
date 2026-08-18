# == Schema Information
#
# Table name: calendar_event_activities
#
#  id                :bigint           not null, primary key
#  action            :string           not null
#  details           :jsonb            not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  calendar_event_id :bigint           not null
#  user_id           :bigint
#
class CalendarEventActivity < ApplicationRecord
  ACTIONS = %w[created updated deleted moved_in_google].freeze

  belongs_to :account
  belongs_to :calendar_event
  belongs_to :user, optional: true

  validates :action, presence: true, inclusion: { in: ACTIONS }
end
