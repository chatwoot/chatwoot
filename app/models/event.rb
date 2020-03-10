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

class Event < ApplicationRecord
  validates :account_id, presence: true
  validates :name, presence: true
  validates :value, presence: true

  belongs_to :account
  belongs_to :user, optional: true
  belongs_to :inbox, optional: true
  belongs_to :conversation, optional: true
end
