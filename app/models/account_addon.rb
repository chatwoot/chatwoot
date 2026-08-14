# == Schema Information
#
# Table name: account_addons
#
#  id              :bigint           not null, primary key
#  duration_months :integer
#  duration_type   :string           default("custom"), not null
#  ends_at         :datetime         not null
#  starts_at       :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  addon_id        :bigint           not null
#
# Indexes
#
#  index_account_addons_on_account_id           (account_id)
#  index_account_addons_on_account_id_and_ends_at  (account_id,ends_at)
#  index_account_addons_on_addon_id             (addon_id)
#
class AccountAddon < ApplicationRecord
  # An AccountAddon activates an Addon (from the catalog) for a specific account
  # for a defined period. The period must fall within the account's current
  # (active) base package period.
  belongs_to :account
  belongs_to :addon

  # Form inputs (dates) resolved into starts_at/ends_at by +resolve_period+.
  attr_accessor :start_date, :end_date

  DURATION_TYPES = %w[fixed_months until_package_end custom].freeze

  scope :current, -> { where('starts_at <= ?', Time.current).where('ends_at >= ?', Time.current) }
  scope :with_active_addon, -> { joins(:addon).where(addons: { status: Addon.statuses[:active] }) }

  # Instance-level counterpart of the +current+ scope, used by views to mark an
  # activation as active vs expired.
  def current?
    Time.current.between?(starts_at, ends_at)
  end

  before_validation :resolve_period

  validates :starts_at, :ends_at, presence: true
  validates :duration_type, inclusion: { in: DURATION_TYPES }
  validates :duration_months, numericality: { only_integer: true, greater_than: 0 }, if: :fixed_months?
  validate :ends_at_after_starts_at
  validate :addon_must_be_active
  validate :period_within_account_package

  def fixed_months?
    duration_type == 'fixed_months'
  end

  private

  # Computes starts_at/ends_at from the duration inputs. start_date is picked by
  # the Super Admin; the end depends on the duration mode (see +resolve_end+).
  # A mode only resolves when its inputs are present, so a record created with
  # explicit dates (e.g. factories) keeps them instead of being zeroed out.
  def resolve_period
    self.starts_at = start_date.to_date.beginning_of_day if start_date.present?

    resolved_end = resolve_end
    self.ends_at = resolved_end if resolved_end.present?
  end

  # fixed_months       -> start + n calendar months, inclusive end of that day
  # until_package_end  -> the account's current base package end (exact)
  # custom             -> the submitted end date
  def resolve_end
    case duration_type
    when 'fixed_months'
      fixed_months_end
    when 'until_package_end'
      current_account_package&.ends_at
    when 'custom'
      end_date.to_date.end_of_day if end_date.present?
    end
  end

  def fixed_months_end
    return if starts_at.blank? || duration_months.blank?

    starts_at.to_date.advance(months: duration_months).end_of_day
  end

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, 'must be after starts_at') if ends_at <= starts_at
  end

  def addon_must_be_active
    return if addon.blank? || addon.active?

    errors.add(:addon, 'is not active and cannot be assigned')
  end

  # The add-on period cannot exceed the account's current base package period.
  # An account without a current active package cannot host an add-on at all.
  def period_within_account_package
    # Package-driven gating lives in the enterprise edition; in a base build the
    # assignment is data-only and there is no package to constrain against.
    return unless account.respond_to?(:current_account_package)
    return if starts_at.blank? || ends_at.blank?

    assignment = current_account_package
    if assignment.blank?
      errors.add(:base, 'account must have a current active package to add an add-on')
      return
    end
    if starts_at < assignment.starts_at
      errors.add(:starts_at, "cannot be before the base package start (#{assignment.starts_at.strftime('%b %d, %Y')})")
    end
    errors.add(:ends_at, "cannot exceed the base package end (#{assignment.ends_at.strftime('%b %d, %Y')})") if ends_at > assignment.ends_at
  end

  def current_account_package
    account.current_account_package
  end
end
