# == Schema Information
#
# Table name: autonomia_prospecting_settings
#
#  id                      :bigint           not null, primary key
#  cache_ttl_seconds       :integer          default(86400), not null
#  daily_limit             :integer
#  default_limit           :integer          default(20), not null
#  enrichment_enabled      :boolean          default(FALSE), not null
#  google_maps_browser_api_key :string
#  google_places_api_key       :string
#  max_results_per_search  :integer          default(20), not null
#  metadata                :jsonb            not null
#  monthly_limit           :integer
#  provider                :string           default("mock"), not null
#  provider_enabled        :boolean          default(FALSE), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  default_crm_pipeline_id :bigint
#  default_crm_stage_id    :bigint
#
# Indexes
#
#  idx_autonomia_prospecting_settings_default_pipeline  (default_crm_pipeline_id)
#  idx_autonomia_prospecting_settings_default_stage     (default_crm_stage_id)
#  index_autonomia_prospecting_settings_on_account_id   (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (default_crm_pipeline_id => crm_pipelines.id) ON DELETE => nullify
#  fk_rails_...  (default_crm_stage_id => crm_pipeline_stages.id) ON DELETE => nullify
#
class Autonomia::Prospecting::Setting < ApplicationRecord
  self.table_name = 'autonomia_prospecting_settings'

  belongs_to :account
  belongs_to :default_crm_pipeline, class_name: 'Crm::Pipeline', optional: true
  belongs_to :default_crm_stage, class_name: 'Crm::PipelineStage', optional: true
  belongs_to :scoring_profile, class_name: 'Autonomia::Prospecting::ScoringProfile', optional: true

  if Chatwoot.encryption_configured?
    encrypts :google_places_api_key
    encrypts :google_maps_browser_api_key
  end

  validates :provider, presence: true
  validates :provider, inclusion: { in: %w[mock google_places] }
  validates :default_limit, numericality: { only_integer: true, greater_than: 0 }
  validates :max_results_per_search, numericality: { only_integer: true, greater_than: 0 }
  validates :daily_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :monthly_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :cache_ttl_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :scoring_mode, inclusion: { in: %w[profile custom] }
  validates :account_id, uniqueness: true
  validate :custom_scoring_weights_must_be_supported_numbers
  validate :default_crm_records_must_belong_to_account

  before_validation :normalize_scoring_configuration

  def self.for_account(account)
    find_or_create_by!(account: account)
  end

  def google_places_configured?
    google_places_api_key.present?
  end

  def google_maps_browser_configured?
    google_maps_browser_api_key.present?
  end

  def active_scoring_profile
    scoring_profile || Autonomia::Prospecting::ScoringProfile.default_profile
  end

  def active_scoring_weights
    return normalized_custom_scoring_weights if scoring_mode == 'custom'

    active_scoring_profile.weights_with_defaults
  end

  private

  def normalize_scoring_configuration
    self.scoring_mode = scoring_mode.presence || 'profile'
    self.custom_scoring_weights = normalized_custom_scoring_weights
    self.scoring_profile ||= Autonomia::Prospecting::ScoringProfile.default_profile if scoring_mode == 'profile'
  end

  def normalized_custom_scoring_weights
    Autonomia::Prospecting::ScoringProfile::DEFAULT_WEIGHTS.keys.index_with do |key|
      value = custom_scoring_weights.to_h[key].presence || Autonomia::Prospecting::ScoringProfile::DEFAULT_WEIGHTS[key]
      value.to_i
    end
  end

  def custom_scoring_weights_must_be_supported_numbers
    return unless scoring_mode == 'custom'

    normalized_custom_scoring_weights.each do |key, value|
      errors.add(:custom_scoring_weights, "#{key} must be between 0 and 100") unless value.to_i.between?(0, 100)
    end
  end

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
