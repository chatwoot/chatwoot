# == Schema Information
#
# Table name: chatbots
#
#  id                          :bigint           not null, primary key
#  inbox_name                  :string
#  last_trained_at             :datetime
#  name                        :string           not null
#  reply_on_connect_with_team  :string
#  reply_on_no_relevant_result :string
#  status                      :string
#  temperature                 :float            default(0.1)
#  text                        :string
#  urls                        :jsonb
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
  include Rails.application.routes.url_helpers

  validates :name, uniqueness: true, presence: true
  belongs_to :account

  has_many_attached :files

  def file_base_data
    files.map do |file|
      {
        id: file.id,
        chatbot_id: id,
        file_type: file.content_type,
        account_id: account_id,
        file_url: url_for(file),
        blob_id: file.blob_id,
        filename: file.filename.to_s,
        metadata: file.metadata
      }
    end
  end
end
