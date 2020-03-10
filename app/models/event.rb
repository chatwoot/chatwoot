# == Schema Information
#
# Table name: events
#
#  id              :bigint           not null, primary key
#  name            :string
#  value           :float
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer
#  conversation_id :integer
#  inbox_id        :integer
#  user_id         :integer
#
# Indexes
#
#  index_events_on_account_id  (account_id)
#  index_events_on_created_at  (created_at)
#  index_events_on_inbox_id    (inbox_id)
#  index_events_on_name        (name)
#  index_events_on_user_id     (user_id)
#

class Event < ApplicationRecord
  validates :account_id, presence: true
  validates :name, presence: true
  validates :value, presence: true

  belongs_to :account
  belongs_to :user, optional: true
  belongs_to :inbox, optional: true
  belongs_to :conversation, optional: true
end
