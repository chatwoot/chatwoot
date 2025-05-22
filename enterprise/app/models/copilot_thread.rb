# == Schema Information
#
# Table name: copilot_threads
#
#  id         :bigint           not null, primary key
#  title      :string           not null
#  uuid       :uuid             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_copilot_threads_on_account_id  (account_id)
#  index_copilot_threads_on_user_id     (user_id)
#  index_copilot_threads_on_uuid        (uuid) UNIQUE
#
class CopilotThread < ApplicationRecord
  belongs_to :user
  belongs_to :account
  has_many :copilot_messages, dependent: :destroy

  validates :title, presence: true
  validates :uuid, presence: true, uniqueness: true
end
