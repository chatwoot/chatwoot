# == Schema Information
#
# Table name: chatbot_items
#
#  id          :bigint           not null, primary key
#  bot_files   :jsonb
#  bot_text    :text
#  bot_urls    :jsonb
#  temperature :float
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  chatbot_id  :integer          not null
#
class ChatbotItem < ApplicationRecord
    belongs_to :chatbot
end
