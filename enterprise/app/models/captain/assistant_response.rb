class Captain::AssistantResponse < ApplicationRecord
  self.table_name = 'captain_assistant_responses'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account
  belongs_to :document, optional: true, class_name: 'Captain::Document'
  has_neighbors :embedding, normalize: true

  validates :question, presence: true
  validates :answer, presence: true

  before_validation :ensure_account
  before_save :update_response_embedding

  scope :ordered, -> { order(created_at: :desc) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_assistant, ->(assistant_id) { where(assistant_id: assistant_id) }
  scope :with_document, ->(document_id) { where(document_id: document_id) }

  private

  def ensure_account
    self.account = assistant&.account
  end

  def update_response_embedding
    # self.embedding = Openai::EmbeddingsService.new.get_embedding("#{question}: #{answer}")
  end
end
