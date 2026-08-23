# == Schema Information
#
# Table name: calendar_events
#
#  id                     :bigint           not null, primary key
#  end_at                 :datetime
#  etag                   :string
#  external_calendar_id   :string           not null
#  google_event_id        :string           not null
#  html_link              :string
#  start_at               :datetime
#  summary                :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  calendar_connection_id :bigint           not null
#  contact_id             :bigint
#  conversation_id        :bigint
#  created_by_id          :bigint
#  updated_by_id          :bigint
#  idempotency_key        :string
#
class CalendarEvent < ApplicationRecord
  belongs_to :account
  belongs_to :calendar_connection
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true
  has_many :activities, class_name: 'CalendarEventActivity', dependent: :destroy

  validates :external_calendar_id, presence: true
  validates :google_event_id, presence: true
  validates :google_event_id, uniqueness: { scope: :calendar_connection_id }
  validates :idempotency_key, uniqueness: { scope: :account_id }, allow_nil: true

  scope :kept, -> { where(deleted_at: nil) }

  def discarded?
    deleted_at.present?
  end
end
