# frozen_string_literal: true

# == Schema Information
#
# Table name: account_feature_flags
#
#  id         :bigint           not null, primary key
#  enabled    :boolean          default(FALSE), not null
#  flag_name  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_account_feature_flags_on_account_id                (account_id)
#  index_account_feature_flags_on_account_id_and_flag_name  (account_id,flag_name) UNIQUE
#  index_account_feature_flags_on_flag_name                 (flag_name)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class AccountFeatureFlag < ApplicationRecord
  belongs_to :account

  validates :flag_name, presence: true
  validates :flag_name, uniqueness: { scope: :account_id }
  validates :enabled, inclusion: { in: [true, false] }

  # Supported feature flags
  SUPPORTED_FLAGS = %w[
    SOCIALWISE_RICH_DASHBOARD
  ].freeze

  validates :flag_name, inclusion: { 
    in: SUPPORTED_FLAGS, 
    message: 'is not a supported feature flag' 
  }

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :for_flag, ->(flag_name) { where(flag_name: flag_name.to_s) }

  after_commit :clear_feature_cache

  # Check if a specific flag is enabled for this account
  # @param flag_name [String, Symbol] The feature flag name
  # @return [Boolean] Whether the flag is enabled
  def self.enabled_for_account?(flag_name, account_id)
    exists?(account_id: account_id, flag_name: flag_name.to_s, enabled: true)
  end

  # Get all enabled flags for an account
  # @param account_id [Integer] The account ID
  # @return [Array<String>] Array of enabled flag names
  def self.enabled_flags_for_account(account_id)
    where(account_id: account_id, enabled: true).pluck(:flag_name)
  end

  # Get all accounts with a specific flag enabled
  # @param flag_name [String, Symbol] The feature flag name
  # @return [ActiveRecord::Relation] Relation of Account records
  def self.accounts_with_flag_enabled(flag_name)
    Account.joins(:account_feature_flags)
           .where(account_feature_flags: { flag_name: flag_name.to_s, enabled: true })
  end

  # Bulk enable flag for multiple accounts
  # @param flag_name [String, Symbol] The feature flag name
  # @param account_ids [Array<Integer>] Array of account IDs
  def self.bulk_enable(flag_name, account_ids)
    flag_name = flag_name.to_s
    
    account_ids.each do |account_id|
      find_or_create_by(account_id: account_id, flag_name: flag_name) do |flag|
        flag.enabled = true
      end
    end
    
    # Clear cache for affected accounts
    account_ids.each { |id| clear_account_cache(flag_name, id) }
  end

  # Bulk disable flag for multiple accounts
  # @param flag_name [String, Symbol] The feature flag name
  # @param account_ids [Array<Integer>] Array of account IDs
  def self.bulk_disable(flag_name, account_ids)
    flag_name = flag_name.to_s
    
    where(account_id: account_ids, flag_name: flag_name)
      .update_all(enabled: false)
    
    # Clear cache for affected accounts
    account_ids.each { |id| clear_account_cache(flag_name, id) }
  end

  private

  def clear_feature_cache
    self.class.clear_account_cache(flag_name, account_id)
  end

  def self.clear_account_cache(flag_name, account_id)
    cache_key = "feature_flag:account:#{account_id}:#{flag_name}"
    Rails.cache.delete(cache_key)
  end
end
