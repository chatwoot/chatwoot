# == Schema Information
#
# Table name: knowledge_source_texts
#
#  id                  :bigint           not null, primary key
#  source_config       :jsonb            not null
#  tab                 :integer          not null
#  text                :text             not null
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
#  index_knowledge_source_texts_on_knowledge_source_id  (knowledge_source_id)
#
# Foreign Keys
#
#  fk_rails_...  (knowledge_source_id => knowledge_sources.id)
#
class KnowledgeSourceText < ApplicationRecord
  belongs_to :knowledge_source
  validates :text, presence: true
  validates :tab, presence: true
  validates :loader_id, presence: true
end
