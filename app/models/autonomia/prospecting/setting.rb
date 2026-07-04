class Autonomia::Prospecting::Setting < ApplicationRecord
  self.table_name = 'autonomia_prospecting_settings'

  belongs_to :account
  encrypts :google_places_api_key if Chatwoot.encryption_configured?

  validates :provider, presence: true
  validates :provider, inclusion: { in: %w[mock google_places] }
  validates :default_limit, numericality: { only_integer: true, greater_than: 0 }
  validates :max_results_per_search, numericality: { only_integer: true, greater_than: 0 }
  validates :cache_ttl_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :account_id, uniqueness: true

  def self.for_account(account)
    find_or_create_by!(account: account)
  end

  def google_places_configured?
    google_places_api_key.present?
  end
end
