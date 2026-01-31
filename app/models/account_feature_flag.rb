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
#  index_account_feature_flags_on_account_id               (account_id)
#  index_account_feature_flags_on_account_id_and_flag_name (account_id,flag_name) UNIQUE
#  index_account_feature_flags_on_flag_name                (flag_name)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class AccountFeatureFlag < ApplicationRecord
  belongs_to :account

  validates :flag_name, presence: true, uniqueness: { scope: :account_id }
  validates :enabled, inclusion: { in: [true, false] }

  # Check if a specific feature flag is enabled for an account
  # @param account [Account] The account to check
  # @param flag_name [String] The name of the feature flag
  # @return [Boolean] true if the flag is enabled, false otherwise
  def self.enabled_for?(account, flag_name)
    flag = find_by(account: account, flag_name: flag_name)
    flag&.enabled || false
  end

  # Enable a feature flag for an account
  # @param account [Account] The account
  # @param flag_name [String] The name of the feature flag
  # @return [AccountFeatureFlag] The created or updated flag
  def self.enable!(account, flag_name)
    flag = find_or_initialize_by(account: account, flag_name: flag_name)
    flag.update!(enabled: true)
    flag
  end

  # Disable a feature flag for an account
  # @param account [Account] The account
  # @param flag_name [String] The name of the feature flag
  # @return [AccountFeatureFlag] The created or updated flag
  def self.disable!(account, flag_name)
    flag = find_or_initialize_by(account: account, flag_name: flag_name)
    flag.update!(enabled: false)
    flag
  end
end
