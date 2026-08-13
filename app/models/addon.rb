# == Schema Information
#
# Table name: addons
#
#  id                      :bigint           not null, primary key
#  campaign_messages_limit :integer
#  channels_limit          :integer
#  contacts_limit          :integer
#  conversations_limit     :integer
#  description             :text
#  ends_at                 :datetime         not null
#  name                    :string           not null
#  starts_at               :datetime         not null
#  status                  :integer          default("active"), not null
#  users_limit             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  package_id              :bigint           not null
#
# Indexes
#
#  index_addons_on_account_id              (account_id)
#  index_addons_on_account_id_and_ends_at  (account_id,ends_at)
#  index_addons_on_package_id              (package_id)
#  index_addons_on_status                  (status)
#
class Addon < ApplicationRecord
  LIMIT_ATTRIBUTES = %i[
    conversations_limit
    contacts_limit
    users_limit
    channels_limit
    campaign_messages_limit
  ].freeze

  enum status: { active: 0, inactive: 1 }

  belongs_to :account
  # The base plan (Package) this add-on boosts. An add-on is an increase to one
  # or more of the base plan's limits, so it only counts while the base plan is
  # active and its period falls within the base plan's period.
  belongs_to :package

  validates :name, presence: true
  # A limit of nil means "no boost". A configured boost is added to the base
  # plan's limit (see Enterprise::Account::PackageLimits#usage_limits).
  validates(*LIMIT_ATTRIBUTES, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true })
  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at
  validate :ends_at_within_base_plan

  # An add-on is "current" when it is active and today falls within its period.
  scope :current, -> { active.where('starts_at <= ?', Time.current).where('ends_at >= ?', Time.current) }

  # The add-on counts only while the base plan it extends is active and running.
  def base_plan_ends_at
    account.account_packages
           .current
           .joins(:package)
           .where(packages: { status: Package.statuses[:active] }, package_id: package_id)
           .order(:starts_at)
           .last
           &.ends_at
  end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, 'must be after starts_at') if ends_at <= starts_at
  end

  def ends_at_within_base_plan
    base_end = base_plan_ends_at
    return if base_end.blank?

    errors.add(:ends_at, "cannot exceed the base plan's end date (#{base_end.strftime('%b %d, %Y')})") if ends_at > base_end
  end
end
