# frozen_string_literal: true

module Aloo
  class AssistantInbox < ApplicationRecord
    self.table_name = 'aloo_assistant_inboxes'

    belongs_to :assistant,
               class_name: 'Aloo::Assistant',
               foreign_key: 'aloo_assistant_id',
               inverse_of: :assistant_inboxes
    belongs_to :inbox

    validates :inbox_id, uniqueness: { message: 'already has an assistant assigned' }

    scope :active, -> { where(active: true) }

    # Delegate account to assistant
    delegate :account, :account_id, to: :assistant
  end
end
