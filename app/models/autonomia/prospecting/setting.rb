class Autonomia::Prospecting::Setting < ApplicationRecord
  self.table_name = 'autonomia_prospecting_settings'

  belongs_to :account
  belongs_to :default_crm_pipeline, class_name: 'Crm::Pipeline', optional: true
  belongs_to :default_crm_stage, class_name: 'Crm::PipelineStage', optional: true

  encrypts :google_places_api_key if Chatwoot.encryption_configured?

  validates :provider, presence: true
  validates :provider, inclusion: { in: %w[mock google_places] }
  validates :default_limit, numericality: { only_integer: true, greater_than: 0 }
  validates :max_results_per_search, numericality: { only_integer: true, greater_than: 0 }
  validates :daily_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :monthly_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :cache_ttl_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :account_id, uniqueness: true
  validate :default_crm_records_must_belong_to_account

  def self.for_account(account)
    find_or_create_by!(account: account)
  end

  def google_places_configured?
    google_places_api_key.present?
  end

  private

  def default_crm_records_must_belong_to_account
    validate_same_account(:default_crm_pipeline)
    validate_same_account(:default_crm_stage)

    return if default_crm_stage.blank? || default_crm_pipeline.blank?
    return if default_crm_stage.pipeline_id == default_crm_pipeline_id

    errors.add(:default_crm_stage, 'must belong to the selected pipeline')
  end

  def validate_same_account(association_name)
    record = public_send(association_name)
    return if record.blank? || account_id.blank?
    return if record.account_id == account_id

    errors.add(association_name, 'must belong to the same account')
  end
end
