module Enterprise::Concerns::Account
  extend ActiveSupport::Concern

  included do
    has_many :sla_policies, dependent: :destroy_async
    has_many :applied_slas, dependent: :destroy_async
    has_many :custom_roles, dependent: :destroy_async

    has_many :aiagent_topics, dependent: :destroy_async, class_name: 'Aiagent::Topic'
    has_many :aiagent_topic_responses, dependent: :destroy_async, class_name: 'Aiagent::TopicResponse'
    has_many :aiagent_documents, dependent: :destroy_async, class_name: 'Aiagent::Document'

    has_many :copilot_threads, dependent: :destroy_async
  end
end
