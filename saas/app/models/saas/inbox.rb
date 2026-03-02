# frozen_string_literal: true

module Saas::Inbox
  extend ActiveSupport::Concern

  prepended do
    has_one :ai_agent_inbox, class_name: 'Saas::AiAgentInbox', dependent: :destroy
    has_one :ai_agent, class_name: 'Saas::AiAgent', through: :ai_agent_inbox
  end
end
