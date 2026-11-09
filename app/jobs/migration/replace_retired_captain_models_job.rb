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
    Account.find_each do |account|
      models = account.captain_models
      next unless models&.values&.any? { |model| RETIRED_MODELS.key?(model) }

      account.update!(captain_models: models.transform_values { |model| RETIRED_MODELS.fetch(model, model) })
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[retired-captain-models] account_id=#{account.id} #{e.record.errors.full_messages.to_sentence}")
    end
  end
end
