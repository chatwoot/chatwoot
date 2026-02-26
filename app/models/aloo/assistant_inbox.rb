# frozen_string_literal: true

# == Schema Information
#
# Table name: aloo_assistant_inboxes
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  aloo_assistant_id :bigint           not null
#  inbox_id          :bigint           not null
#
# Indexes
#
#  index_aloo_assistant_inboxes_on_aloo_assistant_id  (aloo_assistant_id)
#  index_aloo_assistant_inboxes_on_inbox_unique       (inbox_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (aloo_assistant_id => aloo_assistants.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
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

    # Invalidate inbox cache when assignment changes
    after_commit :invalidate_inbox_cache

    private

    def invalidate_inbox_cache
      inbox.account.update_cache_key('inbox')
    end
  end
end
