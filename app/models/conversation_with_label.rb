# == Schema Information
#
# Table name: conversation_with_labels
#
#  id                     :integer
#  additional_attributes  :jsonb
#  agent_last_seen_at     :datetime
#  assignee_last_seen_at  :datetime
#  contact_last_seen_at   :datetime
#  custom_attributes      :jsonb
#  first_reply_created_at :datetime
#  identifier             :string
#  labels_array           :string           is an Array
#  last_activity_at       :datetime
#  priority               :integer
#  snoozed_until          :datetime
#  status                 :integer
#  uuid                   :uuid
#  created_at             :datetime
#  updated_at             :datetime
#  account_id             :integer
#  assignee_id            :integer
#  campaign_id            :bigint
#  contact_id             :bigint
#  contact_inbox_id       :bigint
#  display_id             :integer
#  inbox_id               :integer
#  team_id                :bigint
#
# Indexes
#
#  index_conversation_with_labels_on_account_id         (account_id)
#  index_conversation_with_labels_on_custom_attributes  (custom_attributes) USING gin
#  index_conversation_with_labels_on_id                 (id) UNIQUE
#  index_conversation_with_labels_on_labels_array       (labels_array) USING gin
#  index_conversation_with_labels_on_last_activity_at   (last_activity_at)
#  index_conversation_with_labels_on_status             (status)
#
class ConversationWithLabel < ApplicationRecord
  def self.refresh
    # https://github.com/scenic-views/scenic#what-about-materialized-views
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  def readonly?
    true
  end
end
