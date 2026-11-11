# OpenAI shuts down the GPT-4 series on January 14, 2027 (gpt-4.1-nano on October 23, 2026)
# and its older transcription models on February 26, 2027. It shuts down GPT-5, GPT-5 mini, GPT-5 nano,
# GPT-5 pro, o3, and o3-pro on December 11, 2026.
class Migration::ReplaceRetiredCaptainModelsJob < ApplicationJob
  queue_as :async_database_migration

  TEXT_MODEL = Llm::Config::DEFAULT_MODEL
  TRANSCRIPTION_MODEL = 'gpt-transcribe'.freeze
  RETIRED_MODELS = {
    'gpt-4.1' => TEXT_MODEL,
    'gpt-4.1-mini' => TEXT_MODEL,
    'gpt-4.1-nano' => TEXT_MODEL,
    'gpt-5' => TEXT_MODEL,
    'gpt-5-2025-08-07' => TEXT_MODEL,
    'gpt-5-mini' => TEXT_MODEL,
    'gpt-5-mini-2025-08-07' => TEXT_MODEL,
    'gpt-5-nano' => TEXT_MODEL,
    'gpt-5-nano-2025-08-07' => TEXT_MODEL,
    'gpt-5-pro' => TEXT_MODEL,
    'gpt-5-pro-2025-10-06' => TEXT_MODEL,
    'o3' => TEXT_MODEL,
    'o3-2025-04-16' => TEXT_MODEL,
    'o3-pro' => TEXT_MODEL,
    'o3-pro-2025-06-10' => TEXT_MODEL,
    'gpt-4o-mini-transcribe' => TRANSCRIPTION_MODEL,
    'whisper-1' => TRANSCRIPTION_MODEL
  }.freeze

  def perform
    replace_installation_model
    replace_account_models
  end

  private

  def replace_installation_model
    # A custom endpoint may serve its own deployment under a retired model name, so leave that to the operator.
    return unless Llm::FeatureRouter.standard_openai_endpoint?

    config = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')
    model = config&.value.to_s
    config.update!(value: TEXT_MODEL) if model.start_with?('gpt-4') || RETIRED_MODELS.key?(model)
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
