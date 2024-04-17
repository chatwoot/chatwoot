# == Schema Information
#
# Table name: reporting_events
#
#  id                      :bigint           not null, primary key
#  event_end_time          :datetime
#  event_start_time        :datetime
#  name                    :string
#  value                   :float
#  value_in_business_hours :float
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :integer
#  conversation_id         :integer
#  inbox_id                :integer
#  user_id                 :integer
#
# Indexes
#
#  index_reporting_events_on_account_id            (account_id)
#  index_reporting_events_on_conversation_id       (conversation_id)
#  index_reporting_events_on_created_at            (created_at)
#  index_reporting_events_on_inbox_id              (inbox_id)
#  index_reporting_events_on_name                  (name)
#  index_reporting_events_on_user_id               (user_id)
#  reporting_events__account_id__name__created_at  (account_id,name,created_at)
#

class ReportingEvent < ApplicationRecord
  validates :account_id, presence: true
  validates :name, presence: true
  validates :value, presence: true

  belongs_to :account
  belongs_to :user, optional: true
  belongs_to :inbox, optional: true
  belongs_to :conversation, optional: true

  scope :filter_by_label, lambda { |selected_label|
    joins(:conversation).where(conversations: { cached_label_list: selected_label }) if selected_label.present?
  }

  scope :filter_by_team, lambda { |selected_team|
    joins(:conversation).where(conversations: { team_id: selected_team }) if selected_team.present?
  }

  scope :filter_by_inbox, lambda { |selected_inbox|
    where(inbox_id: selected_inbox) if selected_inbox.present?
  }

  scope :filter_by_rating, lambda { |selected_rating|
    where(conversation_id: ::CsatSurveyResponse.where(rating: selected_rating).select(:conversation_id)) if selected_rating.present?
  }
end
