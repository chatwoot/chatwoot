# == Schema Information
#
# Table name: chatbots
#
#  id              :bigint           not null, primary key
#  chatbot_name    :string
#  last_trained_at :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          default(0), not null
#  chatbot_id      :string           not null
#
class Chatbot < ApplicationRecord
    # Validation to ensure uniqueness of chatbot_id 
    validates :chatbot_id, uniqueness: true
    # Validation to ensure presence of chatbot_id
    validates :chatbot_id, presence: true
end
