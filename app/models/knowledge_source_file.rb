# == Schema Information
#
# Table name: knowledge_source_files
#
#  id                  :bigint           not null, primary key
#  file_name           :string
#  file_size           :integer
#  file_type           :string
#  source_config       :jsonb            not null
#  total_chars         :integer          default(0), not null
#  total_chunks        :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ai_agent_name_id    :string
#  knowledge_source_id :bigint           not null
#  loader_id           :string           not null
#
# Indexes
#
#  index_knowledge_source_files_on_knowledge_source_id  (knowledge_source_id)
#
# Foreign Keys
#
#  fk_rails_...  (knowledge_source_id => knowledge_sources.id)
#
class KnowledgeSourceFile < ApplicationRecord
  belongs_to :knowledge_source

  validates :loader_id, presence: true
  validates :file_name, presence: true
end
