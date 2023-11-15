module Channelable
  extend ActiveSupport::Concern
  included do
    validates :account_id, presence: true
    belongs_to :account
    has_one :inbox, as: :channel, dependent: :destroy_async, touch: true
    after_update :create_audit_log_entry
  end

  def messaging_window_enabled?
    false
  end

  def create_audit_log_entry; end
end

Channelable.prepend_mod_with('Channelable')
