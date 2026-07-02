module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    has_one :call, dependent: :nullify
    has_one :captain_generation, class_name: 'Captain::MessageGeneration', dependent: :destroy_async
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async
  end
end
