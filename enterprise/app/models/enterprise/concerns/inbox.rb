module Enterprise::Concerns::Inbox
  extend ActiveSupport::Concern

  included do
    has_one :captain_inbox, dependent: :destroy
    has_one :assistant,
            through: :captain_inbox,
            class_name: 'Captain::Assistant'
  end
end
