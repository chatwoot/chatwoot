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
#  agent_bot_id            :bigint
#  conversation_id         :integer
#  inbox_id                :integer
#  user_id                 :integer
#
# Indexes
#
#  index_reporting_events_for_response_distribution  (account_id,name,inbox_id,created_at)
#  index_reporting_events_on_account_id              (account_id)
#  index_reporting_events_on_agent_bot_id            (agent_bot_id)
#  index_reporting_events_on_conversation_id         (conversation_id)
#  index_reporting_events_on_created_at              (created_at)
#  index_reporting_events_on_inbox_id                (inbox_id)
#  index_reporting_events_on_name                    (name)
#  index_reporting_events_on_user_id                 (user_id)
#  reporting_events__account_id__name__created_at    (account_id,name,created_at)
#

class ReportingEvent < ApplicationRecord
  validates :account_id, presence: true
  validates :name, presence: true
  validates :value, presence: true

  belongs_to :account
  belongs_to :user, optional: true
  belongs_to :inbox, optional: true
  belongs_to :conversation, optional: true
  belongs_to :agent_bot, optional: true

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

  scope :filter_by_agent_bot_id, lambda { |agent_bot_id|
    where(agent_bot_id: agent_bot_id) if agent_bot_id.present?
  }

  scope :filter_by_name, lambda { |name|
    where(name: name) if name.present?
  }

  RESOLUTION_EVENT_NAMES = %w[conversation_resolved resolution_time_without_bot].freeze

  # Resolution events are stored once per participating agent so that agent reports credit
  # everyone who worked on the conversation. Every other aggregate must see each resolution
  # (conversation + resolution time) once, so keep the first row of each group. When the
  # caller filters rows by agent, the group is restricted to those agents' rows.
  scope :distinct_resolutions, lambda { |user_ids: nil|
    agent_filter = user_ids.present? ? sanitize_sql_array(['AND earlier.user_id IN (?)', user_ids.map(&:to_i)]) : ''

    where(<<~SQL.squish, names: RESOLUTION_EVENT_NAMES)
      reporting_events.name NOT IN (:names) OR NOT EXISTS (
        SELECT 1 FROM reporting_events earlier
        WHERE earlier.conversation_id = reporting_events.conversation_id
          AND earlier.name = reporting_events.name
          AND earlier.event_end_time = reporting_events.event_end_time
          AND earlier.id < reporting_events.id
          #{agent_filter}
      )
    SQL
  }
  scope :filter_by_label_ids, lambda { |label_ids, account_id|
    return all if label_ids.blank?

    label_ids = label_ids.reject(&:blank?)
    return all if label_ids.empty?

    tag_ids = tag_ids_for_labels(label_ids, account_id)
    return none if tag_ids.empty?

    with_conversation_labels(tag_ids)
  }

  def self.tag_ids_for_labels(label_ids, account_id)
    ActsAsTaggableOn::Tag
      .joins('INNER JOIN labels ON labels.title = tags.name')
      .where(labels: { id: label_ids, account_id: account_id })
      .pluck(:id)
  end

  def self.with_conversation_labels(tag_ids)
    joins(<<~SQL.squish)
      INNER JOIN conversations#{' '}
        ON conversations.id = reporting_events.conversation_id
      INNER JOIN taggings#{' '}
        ON taggings.taggable_id = conversations.id#{' '}
        AND taggings.taggable_type = 'Conversation'#{' '}
        AND taggings.context = 'labels'
        AND taggings.tag_id IN (#{sanitize_sql(tag_ids.join(','))})
    SQL
      .distinct
  end
end
