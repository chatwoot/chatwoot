module Enterprise::Concerns::Inbox
  extend ActiveSupport::Concern

  included do
    has_one :captain_inbox, dependent: :destroy, class_name: 'CaptainInbox'
    has_one :captain_assistant,
            through: :captain_inbox,
            class_name: 'Captain::Assistant'
    has_many :inbox_capacity_limits, dependent: :destroy
    has_many :calls, dependent: :destroy_async

    before_create :ensure_create_permitted
  end

  def ensure_create_permitted
    inbox_limit = account[:limits]['inboxes']
    raise CustomExceptions::Inbox::LimitExceeded.new({}) if inbox_limit.present? && account.inboxes.count >= inbox_limit.to_i
  end
end
