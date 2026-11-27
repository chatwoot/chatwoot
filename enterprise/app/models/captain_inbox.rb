# == Schema Information
#
# Table name: captain_inboxes
#
#  id                   :bigint           not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  captain_assistant_id :bigint           not null
#  inbox_id             :bigint           not null
#
# Indexes
#
#  index_captain_inboxes_on_captain_assistant_id               (captain_assistant_id)
#  index_captain_inboxes_on_captain_assistant_id_and_inbox_id  (captain_assistant_id,inbox_id) UNIQUE
#  index_captain_inboxes_on_inbox_id                           (inbox_id)
#
class CaptainInbox < ApplicationRecord
  belongs_to :captain_assistant, class_name: 'Captain::Assistant'
  belongs_to :inbox

  validates :inbox_id, uniqueness: true
  validate :ensure_exclusive_bot_provider

  # The inbox payload names its Captain assistant, so dashboards cache-busting on inboxes refetch it
  after_commit :refresh_inbox_cache, on: [:create, :destroy]

  private

  def refresh_inbox_cache
    inbox.update_account_cache
  end

  def ensure_exclusive_bot_provider
    provider = inbox&.conflicting_bot_provider(:captain)
    errors.add(:base, I18n.t('errors.inboxes.bot_provider_conflict', current_provider: provider, requested_provider: 'Captain')) if provider
  end
end
