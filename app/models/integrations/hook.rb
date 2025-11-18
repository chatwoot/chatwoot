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

  def notion?
    app_id == 'notion'
  end

  def disable
    update(status: 'disabled')
  end

  def process_event(event)
    # Only create span if OTel is enabled and this is an OpenAI hook
    Rails.logger.info "[OTel Debug] process_event called - app_id: #{app_id}, OTEL_ENABLED: #{ENV['OTEL_ENABLED']}, event: #{event['name']}"

    if ENV['OTEL_ENABLED'] == 'true' && app_id == 'openai'
      Rails.logger.info "[OTel Debug] Creating telemetry span for OpenAI event: #{event['name']}"
      process_event_with_telemetry(event)
    else
      Rails.logger.info "[OTel Debug] Skipping telemetry - condition not met"
      process_event_without_telemetry(event)
    end
  end

  private

  def process_event_with_telemetry(event)
    tracer = OpenTelemetry.tracer_provider.tracer('chatwoot.ai_editor')
    Rails.logger.info "[OTel Debug] Tracer created: #{tracer.class}"

    tracer.in_span(
      'ai_editor.process',
      attributes: {
        'gen_ai.system' => 'openai',
        'gen_ai.operation.name' => event['name'],
        'gen_ai.request.model' => 'gpt-4o-mini',
        'app.feature' => 'ai_editor',
        'account.id' => account_id,
        'conversation.id' => event.dig('data', 'conversation_display_id')
      },
      kind: :client
    ) do |span|
      Rails.logger.info "[OTel Debug] Span created: #{span.class}, recording: #{span.recording?}"
      start_time = Time.current

      result = Integrations::Openai::ProcessorService.new(hook: self, event: event).perform

      # Extract token usage and add cost calculation
      if result.is_a?(Hash)
        span.set_attribute('gen_ai.response.success', result[:error].nil?)
        span.set_attribute('gen_ai.response.has_message', result[:message].present?)

        if result[:error]
          span.set_attribute('gen_ai.error.message', result[:error].to_s)
          span.set_attribute('gen_ai.error.code', result[:error_code]) if result[:error_code]
        else
          # Add prompt messages using both indexed and JSON formats for compatibility
          if result[:request_messages].present?
            # Indexed format (standard GenAI semantic convention)
            result[:request_messages].each_with_index do |msg, idx|
              span.set_attribute("gen_ai.prompt.#{idx}.role", msg['role'])
              span.set_attribute("gen_ai.prompt.#{idx}.content", msg['content'])
            end

            # JSON format (alternative for Langfuse)
            span.set_attribute('gen_ai.prompt_json', result[:request_messages].to_json)
          end

          # Add completion output using both indexed and JSON formats
          if result[:message].present?
            completion = { 'role' => 'assistant', 'content' => result[:message] }

            # Indexed format
            span.set_attribute('gen_ai.completion.0.role', 'assistant')
            span.set_attribute('gen_ai.completion.0.content', result[:message])

            # JSON format
            span.set_attribute('gen_ai.completion_json', [completion].to_json)
          end

          # Add Langfuse-specific attributes for better organization
          span.set_attribute('langfuse.tags', [event['name'], 'ai_editor'].to_json)

          # Add token usage - Langfuse expects these attribute names
          # Langfuse will auto-calculate cost from model + token counts
          if result[:usage]
            usage = result[:usage]
            span.set_attribute('gen_ai.usage.prompt_tokens', usage['prompt_tokens']) if usage['prompt_tokens']
            span.set_attribute('gen_ai.usage.completion_tokens', usage['completion_tokens']) if usage['completion_tokens']
          end
        end
      end

      result
    rescue StandardError => e
      # Let the span record the error
      span.record_exception(e)
      span.status = OpenTelemetry::Trace::Status.error("Error processing OpenAI event: #{e.message}")
      raise
    end
  end

  def process_event_without_telemetry(event)
    case app_id
    when 'openai'
      Integrations::Openai::ProcessorService.new(hook: self, event: event).perform if app_id == 'openai'
    else
      { error: 'No processor found' }
    end
  end

  public

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

    errors.add(:settings, ': Invalid settings data') unless JSONSchemer.schema(app.params[:settings_json_schema]).valid?(settings)
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
