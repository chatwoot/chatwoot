# == Schema Information
#
# Table name: chatbot_items
#
#  id          :bigint           not null, primary key
#  files       :jsonb
#  temperature :float
#  text        :text
#  urls        :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  chatbot_id  :integer          not null
#
class ChatbotItem < ApplicationRecord
end
