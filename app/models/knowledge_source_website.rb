# == Schema Information
#
# Table name: knowledge_source_websites
#
#  id                  :bigint           not null, primary key
#  content             :text             default(""), not null
#  parent_url          :string           not null
#  total_chars         :integer          not null
#  total_chunks        :integer          not null
#  url                 :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ai_agent_name_id    :string
#  knowledge_source_id :bigint           not null
#  loader_id           :string           not null
#
# Indexes
#
#  index_knowledge_source_websites_on_knowledge_source_id  (knowledge_source_id)
#
# Foreign Keys
#
#  fk_rails_...  (knowledge_source_id => knowledge_sources.id)
#
class KnowledgeSourceWebsite < ApplicationRecord
  belongs_to :knowledge_source

  validates :url, presence: true
  validates :parent_url, presence: true
  validates :loader_id, presence: true

  def self.add_record!(url:, parent_url:, content:, document_loader:)
    create!(
      url: url,
      parent_url: parent_url,
      content: content,
      loader_id: document_loader['docId'],
      total_chars: document_loader.dig('file', 'totalChars'),
      total_chunks: document_loader.dig('file', 'totalChunks')
    )
  end

  def self.update_record!(params:, document_loader:)
    knowledge_source_website = find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound, 'Knowledge source website not found' if knowledge_source_website.nil?

    previous_loader_id = knowledge_source_website.loader_id

    knowledge_source_website.update!(
      content: params[:markdown],
      loader_id: document_loader['docId'],
      total_chars: document_loader.dig('file', 'totalChars'),
      total_chunks: document_loader.dig('file', 'totalChunks')
    )

    { updated: knowledge_source_website, previous_loader_id: previous_loader_id }
  end
end
