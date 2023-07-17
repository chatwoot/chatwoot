module Enterprise::Concerns::Account
  extend ActiveSupport::Concern

  included do
    has_many :sla_policies, dependent: :destroy_async
    has_many :response_sources, dependent: :destroy_async
    has_many :response_documents, dependent: :destroy_async
    has_many :responses, dependent: :destroy_async
  end
end
