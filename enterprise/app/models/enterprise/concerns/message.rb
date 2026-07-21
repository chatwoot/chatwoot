module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    has_one :call, dependent: :nullify
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async
    has_many :captain_message_sources, class_name: 'Captain::MessageSource', dependent: :destroy_async
  end
end
