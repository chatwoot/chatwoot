# == Schema Information
#
# Table name: knowledge_source_websites
#
#  id                  :bigint           not null, primary key
#  content             :text             default(""), not null
#  loader_ids          :string           default([]), is an Array
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
  validates :content, length: { maximum: 100_000 }
end
