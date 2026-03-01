class Saas::AiUsageRecord < ApplicationRecord
  self.table_name = 'saas_ai_usage_records'

  belongs_to :account

  validates :provider, :model, :recorded_on, presence: true
  validates :tokens_input, :tokens_output, numericality: { greater_than_or_equal_to: 0 }

  scope :for_period, ->(start_date, end_date) { where(recorded_on: start_date..end_date) }
  scope :current_month, -> { for_period(Time.current.beginning_of_month.to_date, Time.current.to_date) }

  def total_tokens
    tokens_input + tokens_output
  end

  def self.monthly_usage(account_id)
    current_month.where(account_id: account_id).sum('tokens_input + tokens_output')
  end

  def self.record_usage!(account:, provider:, model:, tokens_input:, tokens_output:, cost_microcents: 0, feature: nil)
    create!(
      account: account,
      provider: provider,
      model: model,
      tokens_input: tokens_input,
      tokens_output: tokens_output,
      cost_microcents: cost_microcents,
      feature: feature,
      recorded_on: Time.current.to_date
    )
  end
end
