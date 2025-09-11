# == Schema Information
#
# Table name: knowledge_source_qnas
#
#  id                  :bigint           not null, primary key
#  answer              :text             not null
#  question            :string           not null
#  source_config       :jsonb            not null
#  total_chars         :integer          default(0), not null
#  total_chunks        :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ai_agent_name_id    :string
#  knowledge_source_id :bigint           not null
#  loader_id           :string           default(""), not null
#
# Indexes
#
#  index_knowledge_source_qnas_on_knowledge_source_id  (knowledge_source_id)
#
# Foreign Keys
#
#  fk_rails_...  (knowledge_source_id => knowledge_sources.id)
#
class KnowledgeSourceQna < ApplicationRecord
  belongs_to :knowledge_source

  validates :question, :answer, presence: true

  def self.create_or_update(qna_param, document_loader)
    if qna_param[:id].present?
      update_record(qna_param: qna_param, document_loader: document_loader)
    else
      create_record(qna_param: qna_param, document_loader: document_loader)
    end
  end

  def self.create_record(qna_param:, document_loader:)
    new_qna = create!(
      question: qna_param[:question],
      answer: qna_param[:answer],
      loader_id: document_loader['docId'],
      total_chars: document_loader.dig('file', 'totalChars'),
      total_chunks: document_loader.dig('file', 'totalChunks')
    )

    { qna: new_qna, previous_loader_id: nil }
  end

  def self.update_record(qna_param:, document_loader:)
    knowledge_source_qna = find_by(id: qna_param[:id])
    raise ActiveRecord::RecordNotFound, 'Knowledge source qna not found' unless knowledge_source_qna

    previous_loader_id = knowledge_source_qna.loader_id

    knowledge_source_qna.update!(
      question: qna_param[:question],
      answer: qna_param[:answer],
      loader_id: document_loader['docId'],
      total_chars: document_loader.dig('file', 'totalChars'),
      total_chunks: document_loader.dig('file', 'totalChunks')
    )

    { qna: knowledge_source_qna, previous_loader_id: previous_loader_id }
  end
end
