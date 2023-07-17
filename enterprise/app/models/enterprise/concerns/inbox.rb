module Enterprise::Concerns::Inbox
  extend ActiveSupport::Concern

  included do
    has_many :response_sources, dependent: :destroy_async
    has_many :response_documents, through: :response_sources
    has_many :responses, through: :response_documents
  end
end
