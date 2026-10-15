# OpenAI shuts down the GPT-4 series on January 14, 2027 (gpt-4.1-nano on October 23, 2026)
# and its older transcription models on February 26, 2027.
class Migration::ReplaceRetiredCaptainModelsJob < ApplicationJob
  queue_as :async_database_migration

  TEXT_MODEL = Llm::Config::DEFAULT_MODEL
  TRANSCRIPTION_MODEL = 'gpt-transcribe'.freeze
  RETIRED_MODELS = {
    'gpt-4.1' => TEXT_MODEL,
    'gpt-4.1-mini' => TEXT_MODEL,
    'gpt-4.1-nano' => TEXT_MODEL,
    'gpt-4o-mini-transcribe' => TRANSCRIPTION_MODEL,
    'whisper-1' => TRANSCRIPTION_MODEL
  }.freeze

  def perform
    replace_installation_model
    replace_account_models
  end

  private

  def replace_installation_model
    # A custom endpoint may serve its own deployment under a GPT-4 name, so leave that to the operator.
    return unless Llm::FeatureRouter.standard_openai_endpoint?

    config = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')
    config.update!(value: TEXT_MODEL) if config&.value.to_s.start_with?('gpt-4')
  end

  def replace_account_models
    Account.where("settings ->> 'captain_models' SIMILAR TO ?", '%(gpt-4|whisper-1)%').find_each do |account|
      models = account.captain_models.transform_values { |model| RETIRED_MODELS.fetch(model, model) }
      # Writes only the remapped settings; full validation would block on unrelated account data.
      account.update_columns(settings: account.settings.merge('captain_models' => models)) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
