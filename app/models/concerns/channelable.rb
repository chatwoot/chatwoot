module Channelable
  extend ActiveSupport::Concern
  included do
    validates :account_id, presence: true
    belongs_to :account
    has_one :inbox, as: :channel, dependent: :destroy_async, touch: true
    before_create :ensure_inbox_create_permitted
    after_update :create_audit_log_entry
  end

  def create_audit_log_entry; end

  private

  def ensure_inbox_create_permitted
    Inbox.ensure_create_permitted!(account)
  end
end

Channelable.prepend_mod_with('Channelable')
