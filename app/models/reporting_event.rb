# == Schema Information
#
# Table name: reporting_events
#
#  id                      :bigint           not null, primary key
#  channel_type            :string
#  conversation_created_at :datetime
#  event_end_time          :datetime
#  event_start_time        :datetime
#  from_state              :string
#  name                    :string
#  value                   :float
#  value_in_business_hours :float
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :integer
#  conversation_id         :integer
#  inbox_id                :integer
#  team_id                 :bigint
#  user_id                 :integer
#
# Indexes
#
#  idx_reporting_events_on_account_channel_name_created     (account_id,channel_type,name,created_at)
#  idx_reporting_events_on_account_conv_created_at_name     (account_id,conversation_created_at,name)
#  idx_reporting_events_on_account_from_state_name_created  (account_id,from_state,name,created_at)
#  idx_reporting_events_on_account_team_name_created        (account_id,team_id,name,created_at)
#  index_reporting_events_on_account_id                     (account_id)
#  index_reporting_events_on_conversation_id                (conversation_id)
#  index_reporting_events_on_created_at                     (created_at)
#  index_reporting_events_on_inbox_id                       (inbox_id)
#  index_reporting_events_on_name                           (name)
#  index_reporting_events_on_user_id                        (user_id)
#  reporting_events__account_id__name__created_at           (account_id,name,created_at)
#

class ReportingEvent < ApplicationRecord
  validates :account_id, presence: true
  validates :name, presence: true
  validates :value, presence: true

  belongs_to :account
  belongs_to :user, optional: true
  belongs_to :inbox, optional: true
  belongs_to :conversation, optional: true
  belongs_to :team, optional: true

  # Scopes for filtering
  scope :filter_by_date_range, lambda { |range|
    where(created_at: range) if range.present?
  }

  scope :filter_by_inbox_id, lambda { |inbox_id|
    where(inbox_id: inbox_id) if inbox_id.present?
  }

  scope :filter_by_user_id, lambda { |user_id|
    where(user_id: user_id) if user_id.present?
  }

  scope :filter_by_name, lambda { |name|
    where(name: name) if name.present?
  }

  scope :filter_by_team_id, lambda { |team_id|
    where(team_id: team_id) if team_id.present?
  }

  scope :filter_by_channel_type, lambda { |channel_type|
    where(channel_type: channel_type) if channel_type.present?
  }
end
