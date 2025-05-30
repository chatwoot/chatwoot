# == Schema Information
#
# Table name: ai_agent_documents
#
#  id           :bigint           not null, primary key
#  name         :string
#  external_link :string           not null
#  content      :text
#  topic_id     :bigint           not null
#  account_id   :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  status       :integer          default(0), not null
#
# Indexes
#
#  index_ai_agent_documents_on_account_id              (account_id)
#  index_ai_agent_documents_on_topic_id                (topic_id)
#  index_ai_agent_documents_on_topic_id_and_external_link  (topic_id,external_link) UNIQUE
#
class AIAgent::Document < ApplicationRecord
  self.table_name = 'ai_agent_documents'

  belongs_to :topic, class_name: 'AIAgent::Topic'
  belongs_to :account
  has_many :responses, class_name: 'AIAgent::TopicResponse', as: :documentable, dependent: :destroy_async

  validates :external_link, presence: true
  validates :external_link, uniqueness: { scope: :topic_id }
  validates :account_id, presence: true

  before_validation :ensure_account

  scope :ordered, -> { order(created_at: :desc) }
  enum status: { pending: 0, active: 1 }

  private

  def ensure_account
    self.account = topic&.account
  end
end 