# == Schema Information
#
# Table name: chatbots
#
#  id              :bigint           not null, primary key
#  bot_status      :string
#  chatbot_name    :string           not null
#  inbox_name      :string
#  last_trained_at :datetime
#  temperature     :float            default(0.1)
#  website_token   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :string           default("0"), not null
#  inbox_id        :integer
#
class Chatbot < ApplicationRecord
  validates :chatbot_name, uniqueness: true
  validates :chatbot_name, presence: true
  belongs_to :account
end
