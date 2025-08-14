# == Schema Information
#
# Table name: knowledge_sources
#
#  id           :bigint           not null, primary key
#  name         :string           not null
#  store_config :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  ai_agent_id  :bigint           not null
#  store_id     :string           not null
#
# Indexes
#
#  index_knowledge_sources_on_ai_agent_id  (ai_agent_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (ai_agent_id => ai_agents.id)
#
class KnowledgeSource < ApplicationRecord
  belongs_to :ai_agent
  has_many :knowledge_source_texts, dependent: :destroy
  has_many :knowledge_source_files, dependent: :destroy
  has_many :knowledge_source_websites, dependent: :destroy
  has_many :knowledge_source_qnas, dependent: :destroy

  validates :name, presence: true
  validates :ai_agent_id, presence: true
  validates :store_id, presence: true

  def not_empty?
    knowledge_source_texts.exists? ||
      knowledge_source_files.exists? ||
      knowledge_source_websites.exists? ||
      knowledge_source_qnas.exists?
  end

  def add_text!(content:, document_loader:)
    knowledge_source_texts.create!(
      text: content[:text],
      tab: content[:tab],
      loader_id: document_loader['docId'],
      total_chars: document_loader.dig('file', 'totalChars'),
      total_chunks: document_loader.dig('file', 'totalChunks')
    )
  rescue StandardError => e
    Rails.logger.error("Failed to create knowledge source text: #{e.record.errors.full_messages.join(', ')}")
    raise e
  end

  def update_text!(content:, document_loader:)
    knowledge_source_text = knowledge_source_texts.find_by(id: content['id'])
    raise ActiveRecord::RecordNotFound, 'Knowledge source text not found' if knowledge_source_text.nil?

    previous_loader_id = knowledge_source_text.loader_id

    knowledge_source_text.update!(
      text: content[:text],
      tab: content[:tab],
      loader_id: document_loader['docId'],
      total_chars: document_loader.dig('file', 'totalChars'),
      total_chunks: document_loader.dig('file', 'totalChunks')
    )

    {
      knowledge_source_text: knowledge_source_text,
      previous_loader_id: previous_loader_id
    }
  rescue StandardError => e
    Rails.logger.error("Failed to update knowledge source text: #{e.record.errors.full_messages.join(', ')}")
    raise e
  end

  def add_file!(file:, document_loader:)
    knowledge_source_files.create!(
      loader_id: document_loader['docId'],
      file_name: document_loader.dig('file', 'loaderName'),
      file_type: file.content_type,
      file_size: file.size,
      total_chunks: document_loader.dig('file', 'totalChunks'),
      total_chars: document_loader.dig('file', 'totalChars')
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create knowledge source file: #{e.record.errors.full_messages.join(', ')}")
    raise e
  rescue StandardError => e
    Rails.logger.error("Unexpected error occurred: #{e.message}")
    raise e
  end

  def add_excel_file!(file:, result:)
    Rails.logger.info "Adding Excel file with result: #{result.inspect}"

    knowledge_source_files.create!(
      loader_id: result[:import_id],
      file_name: file.file_name,
      file_type: file.content_type,
      file_size: file.size,
      total_chunks: 0, # Excel files don't have chunks
      total_chars: 0 # Excel files don't have chars
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create knowledge source file: #{e.record.errors.full_messages.join(', ')}")
    raise e
  rescue StandardError => e
    Rails.logger.error("Unexpected error occurred: #{e.message}")
    raise e
  end
end
