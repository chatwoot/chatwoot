# == Schema Information
#
# Table name: integrations_hooks
#
#  id           :bigint           not null, primary key
#  access_token :string
#  hook_type    :integer          default("account")
#  settings     :jsonb
#  status       :integer          default("enabled")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#  app_id       :string
#  inbox_id     :integer
#  reference_id :string
#
class Integrations::Hook < ApplicationRecord
  include Reauthorizable

  attr_readonly :app_id, :account_id, :inbox_id, :hook_type
  before_validation :ensure_hook_type
  after_create :trigger_setup_if_crm

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  encrypts :access_token, deterministic: true if Chatwoot.encryption_configured?

  validates :account_id, presence: true
  validates :app_id, presence: true
  validates :inbox_id, presence: true, if: -> { hook_type == 'inbox' }
  validate :validate_settings_json_schema
  validate :ensure_feature_enabled
  validate :validate_openai_api_key, if: :validate_openai_api_key?
  validate :validate_cloudflare_realtimekit_credentials, if: :validate_cloudflare_realtimekit_credentials?
  validates :app_id, uniqueness: { scope: [:account_id], unless: -> { app.present? && app.params[:allow_multiple_hooks].present? } }

  # TODO: This seems to be only used for slack at the moment
  # We can add a validator when storing the integration settings and toggle this in future
  enum status: { disabled: 0, enabled: 1 }

  belongs_to :account
  belongs_to :inbox, optional: true
  has_secure_token :access_token

  enum hook_type: { account: 0, inbox: 1 }

  scope :account_hooks, -> { where(hook_type: 'account') }
  scope :inbox_hooks, -> { where(hook_type: 'inbox') }

  def app
    @app ||= Integrations::App.find(id: app_id)
  end

  def slack?
    app_id == 'slack'
  end

  def dialogflow?
    app_id == 'dialogflow'
  end

  def openai?
    app_id == 'openai'
  end

  def dyte?
    app_id == 'dyte'
  end

  def notion?
    app_id == 'notion'
  end

  def disable
    update(status: 'disabled')
  end

  def process_event(_event)
    # OpenAI integration migrated to Captain::EditorService
    # Other integrations (slack, dialogflow, etc.) handled via HookJob
    { error: 'No processor found' }
  end

  def feature_allowed?
    return true if app.blank?

    flag = app.params[:feature_flag]
    return true unless flag

    account.feature_enabled?(flag)
  end

  private

  def ensure_feature_enabled
    errors.add(:feature_flag, 'Feature not enabled') unless feature_allowed?
  end

  def ensure_hook_type
    self.hook_type = app.params[:hook_type] if app.present?
  end

  def validate_settings_json_schema
    return if app.blank? || app.params[:settings_json_schema].blank?
    return if legacy_dyte_settings_unchanged?

    errors.add(:settings, ': Invalid settings data') unless JSONSchemer.schema(app.params[:settings_json_schema]).valid?(settings)
  end

  # TODO: When adding credential validation for other integrations (dialogflow, dyte, etc.),
  # extract this into an app-level config flag in apps.yml instead of hardcoding app_id checks.
  def validate_openai_api_key?
    openai? && enabled? && (new_record? || openai_api_key_changed? || will_save_change_to_status?)
  end

  def validate_cloudflare_realtimekit_credentials?
    dyte? && enabled? && !legacy_dyte_settings_unchanged? &&
      (new_record? || cloudflare_realtimekit_credentials_changed? || will_save_change_to_status?)
  end

  def openai_api_key_changed?
    settings_api_key(settings) != settings_api_key(settings_in_database)
  end

  def cloudflare_realtimekit_credentials_changed?
    settings_cloudflare_realtimekit_credentials(settings) != settings_cloudflare_realtimekit_credentials(settings_in_database)
  end

  def legacy_dyte_settings_unchanged?
    dyte? && persisted? && !will_save_change_to_settings? && legacy_dyte_settings?(settings_in_database)
  end

  def legacy_dyte_settings?(value)
    return false if value.blank?

    %w[organization_id api_key].any? { |key| settings_value(value, key).present? } &&
      %w[account_id app_id api_token].none? { |key| settings_value(value, key).present? }
  end

  def validate_openai_api_key
    return if Integrations::Openai::KeyValidator.valid?(settings_api_key(settings))

    errors.add(:base, I18n.t('errors.openai.invalid_api_key'))
  end

  def validate_cloudflare_realtimekit_credentials
    result = Integrations::Cloudflare::RealtimeKitCredentialsValidator.validate(*settings_cloudflare_realtimekit_credentials(settings))
    return if result.success?

    errors.add(:base, I18n.t("errors.cloudflare.realtimekit.#{result.error}"))
  end

  def settings_api_key(value)
    settings_value(value, 'api_key')
  end

  def settings_cloudflare_realtimekit_credentials(value)
    [
      settings_value(value, 'account_id'),
      settings_value(value, 'app_id'),
      settings_value(value, 'api_token')
    ]
  end

  def settings_value(value, key)
    value&.dig(key) || value&.dig(key.to_sym)
  end

  def trigger_setup_if_crm
    # we need setup services to create data prerequisite to functioning of the integration
    # in case of Leadsquared, we need to create a custom activity type for capturing conversations and transcripts
    # https://apidocs.leadsquared.com/create-new-activity-type-api/
    return unless crm_integration?

    ::Crm::SetupJob.perform_later(id)
  end

  def crm_integration?
    %w[leadsquared].include?(app_id)
  end
end
