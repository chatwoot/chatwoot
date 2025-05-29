module Enterprise::Concerns::Inbox
  extend ActiveSupport::Concern

  included do
    has_one :aiagent_inbox, dependent: :destroy, class_name: 'AiagentInbox'
    has_one :aiagent_topic,
            through: :aiagent_inbox,
            class_name: 'Aiagent::Topic'
  end
end
