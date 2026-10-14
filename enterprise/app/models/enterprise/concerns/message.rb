module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    include ConversationMonitors::MessageTracking
    has_one :call, dependent: :nullify
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async
  end
end
