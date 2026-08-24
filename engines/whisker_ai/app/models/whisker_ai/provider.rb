# == Schema Information
#
# Table name: whisker_ai_providers
#
#  id             :bigint           not null, primary key
#  account_id     :bigint           not null
#  name           :string           not null
#  base_url       :string           not null
#  api_key        :string
#  models         :jsonb            not null, is an Array
#  is_primary     :boolean          default(FALSE)
#  fallback_order :integer          default(0)
#  monthly_cap    :decimal(10, 2)
#  enabled        :boolean          default(TRUE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_whisker_ai_providers_on_account_id  (account_id)
#  index_whisker_ai_providers_on_primary     (account_id, is_primary) WHERE is_primary = true
#

class WhiskerAi::Provider < ApplicationRecord
  self.table_name = 'whisker_ai_providers'

  encrypts :api_key, deterministic: true if Chatwoot.encryption_configured?

  belongs_to :account

  validates :name, presence: true
  validates :base_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :models, presence: true
  validate :at_most_one_primary_per_account, if: :is_primary?

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(:fallback_order) }
  scope :primary, -> { where(is_primary: true) }

  def api_base
    "#{base_url.chomp('/')}/v1"
  end

  def openai_compatible?
    true # All BYOR providers are OpenAI-compatible by design
  end

  private

  def at_most_one_primary_per_account
    existing = account.whisker_ai_providers.primary.where.not(id: id)
    errors.add(:is_primary, 'can only have one primary provider per account') if existing.exists?
  end
end
