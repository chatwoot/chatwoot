# Captain models lived behind enterprise-scoped associations upstream; this
# build keeps them directly on Account so the open-source Captain modules
# (assistants, documents, responses, simple replies) stay functional.
module AccountCaptainAssociations
  extend ActiveSupport::Concern

  included do
    has_many :captain_assistants, dependent: :destroy_async, class_name: 'Captain::Assistant'
    has_many :captain_assistant_responses, dependent: :destroy_async, class_name: 'Captain::AssistantResponse'
    has_many :captain_documents, dependent: :destroy_async, class_name: 'Captain::Document'
    has_many :captain_faq_observations, dependent: :destroy_async, class_name: 'Captain::FaqObservation'
    has_many :captain_faq_suggestions, dependent: :destroy_async, class_name: 'Captain::FaqSuggestion'
    has_many :captain_custom_tools, dependent: :destroy_async, class_name: 'Captain::CustomTool'
    has_many :captain_agent_sessions, dependent: :destroy_async, class_name: 'Captain::AgentSession'
    has_many :captain_simple_replies, dependent: :destroy_async, class_name: 'Captain::SimpleReply'
  end
end
