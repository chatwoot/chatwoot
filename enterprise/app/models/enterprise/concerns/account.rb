module Enterprise::Concerns::Account
  extend ActiveSupport::Concern

  included do
    has_many :sla_policies, dependent: :destroy_async
    has_many :applied_slas, dependent: :destroy_async
    has_many :custom_roles, dependent: :destroy_async

    def self.add_response_related_associations
      has_many :response_sources, dependent: :destroy_async
      has_many :response_documents, dependent: :destroy_async
      has_many :responses, dependent: :destroy_async
    end

    add_response_related_associations if Features::ResponseBotService.new.vector_extension_enabled?
  end
end
