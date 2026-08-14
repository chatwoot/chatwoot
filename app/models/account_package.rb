# == Schema Information
#
# Table name: account_packages
#
#  id         :bigint           not null, primary key
#  ends_at    :datetime         not null
#  starts_at  :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  package_id :bigint           not null
#
# Indexes
#
#  index_account_packages_on_account_id              (account_id)
#  index_account_packages_on_account_id_and_ends_at  (account_id,ends_at)
#  index_account_packages_on_package_id              (package_id)
#
class AccountPackage < ApplicationRecord
  belongs_to :account
  belongs_to :package

  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at

  scope :current, -> { where('starts_at <= ?', Time.current).where('ends_at >= ?', Time.current) }

  # The package controls the account's active/inactive status: assigning an
  # active package that is already in effect activates the account, while
  # removing/re-timing a package re-syncs the account status. Runtime gating is
  # handled by Account#active? (derived), so this only keeps the stored status
  # column accurate for the Super Admin list and scopes.
  after_create :sync_account_status
  after_update :sync_account_status
  after_destroy :sync_account_status

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, 'must be after starts_at') if ends_at <= starts_at
  end

  def sync_account_status
    return if account.destroyed?
    # Package-driven gating lives in the enterprise edition; in a base build the
    # assignment is data-only and does not flip the account status.
    return unless account.respond_to?(:package_active?)

    account.package_active? ? account.active! : account.suspended!
  end
end
