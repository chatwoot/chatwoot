# == Schema Information
#
# Table name: chatbots
#
#  id                          :bigint           not null, primary key
#  inbox_name                  :string
#  last_trained_at             :datetime
#  name                        :string           not null
#  reply_on_no_relevant_result :string
#  status                      :string
#  temperature                 :float            default(0.1)
#  website_token               :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_id                  :string           default("0"), not null
#  inbox_id                    :integer
#
# Indexes
#
#  index_chatbots_on_account_id  (account_id)
#
class Chatbot < ApplicationRecord
  validates :name, uniqueness: true, presence: true
  belongs_to :account
end
