# == Schema Information
#
# Table name: chatbot_items
#
#  id          :bigint           not null, primary key
#  temperature :float
#  text        :text
#  urls        :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  chatbot_id  :integer          not null
#
class ChatbotItem < ApplicationRecord
  has_many_attached :files

  def file_base_data
    files.map do |file|
      {
        id: file.id,
        automation_rule_id: id,
        file_type: file.content_type,
        account_id: account_id,
        file_url: url_for(file),
        blob_id: file.blob_id,
        filename: file.filename.to_s
      }
    end
  end
end
