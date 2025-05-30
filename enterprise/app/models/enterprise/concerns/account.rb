module Enterprise::Concerns::Account
  extend ActiveSupport::Concern

  included do
    has_many :sla_policies, dependent: :destroy_async
    has_many :applied_slas, dependent: :destroy_async
    has_many :custom_roles, dependent: :destroy_async

    has_many :ai_agent_topics, dependent: :destroy_async, class_name: 'AIAgent::Topic'
    has_many :ai_agent_topic_responses, dependent: :destroy_async, class_name: 'AIAgent::TopicResponse'
    has_many :ai_agent_documents, dependent: :destroy_async, class_name: 'AIAgent::Document'

    has_many :copilot_threads, dependent: :destroy_async
  end
end
