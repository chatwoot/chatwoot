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
  before_validation :ensure_captain_config_present, on: :create
  before_validation :ensure_hook_type

  validates :account_id, presence: true
  validates :app_id, presence: true
  validates :inbox_id, presence: true, if: -> { hook_type == 'inbox' }
  validate :validate_settings_json_schema
  validates :app_id, uniqueness: { scope: [:account_id], unless: -> { app.present? && app.params[:allow_multiple_hooks].present? } }

  # TODO: This seems to be only used for slack at the moment
  # We can add a validator when storing the integration settings and toggle this in future
  enum status: { disabled: 0, enabled: 1 }

  belongs_to :account
  belongs_to :inbox, optional: true
  has_secure_token :access_token

  enum hook_type: { account: 0, inbox: 1 }

  def app
    @app ||= Integrations::App.find(id: app_id)
  end

  def slack?
    app_id == 'slack'
  end

  def dialogflow?
    app_id == 'dialogflow'
  end

  def disable
    update(status: 'disabled')
  end

  def process_event(event)
    case app_id
    when 'openai'
      Integrations::Openai::ProcessorService.new(hook: self, event: event).perform if app_id == 'openai'
    else
      { error: 'No processor found' }
    end
  end

  private

  def ensure_captain_config_present
    return if app_id != 'captain'
    # Already configured, skip this
    return if settings['access_token'].present?

    ensure_captain_is_enabled
    fetch_and_set_captain_settings
  end

  def ensure_captain_is_enabled
    raise 'Captain is not enabled' unless Integrations::App.find(id: 'captain').active?(account)
  end

  def fetch_and_set_captain_settings
    captain_response = ChatwootHub.get_captain_settings(account)
    raise "Failed to get captain settings: #{captain_response.body}" unless captain_response.success?

    captain_settings = JSON.parse(captain_response.body)
    settings['account_email'] = captain_settings['account_email']
    settings['account_id'] = captain_settings['captain_account_id'].to_s
    settings['access_token'] = captain_settings['access_token']
    settings['assistant_id'] = captain_settings['assistant_id'].to_s
  end

  def ensure_hook_type
    self.hook_type = app.params[:hook_type] if app.present?
  end

  def validate_settings_json_schema
    return if app.blank? || app.params[:settings_json_schema].blank?

    errors.add(:settings, ': Invalid settings data') unless JSONSchemer.schema(app.params[:settings_json_schema]).valid?(settings)
  end
end
