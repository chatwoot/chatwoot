# == Schema Information
#
# Table name: knowledge_bases
#
#  id          :uuid             not null, primary key
#  name        :string
#  source_type :integer
#  url         :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_knowledge_bases_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class KnowledgeBase < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :account
  has_many_attached :files

  validates :name, presence: true
  validates :account_id, presence: true
  validates :url, presence: true, if: :webpage_type?

  enum source_type: { webpage: 0, file: 1, image: 2 }

  def file_base_data
    files.map do |file|
      {
        id: file.id,
        knowledge_base_id: id,
        file_type: file.content_type,
        account_id: account_id,
        file_url: url_for(file),
        blob_id: file.blob_id,
        filename: file.filename.to_s
      }
    end
  end

  private

  def webpage_type?
    source_type == 'webpage'
  end
end
