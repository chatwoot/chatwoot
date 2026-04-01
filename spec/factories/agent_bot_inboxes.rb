# == Schema Information
#
# Table name: agent_bot_inboxes
#
#  id           :bigint           not null, primary key
#  status       :integer          default("active")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#  agent_bot_id :integer
#  inbox_id     :integer
#
FactoryBot.define do
  factory :agent_bot_inbox do
    inbox
    agent_bot
    status { 'active' }
  end
end
