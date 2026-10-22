class Llm::TextToSpeechService < Llm::LegacyBaseOpenAiService
  VOICE = 'alloy'.freeze

  attr_reader :text, :account

  def self.available_for?(account)
    account.feature_enabled?('captain_integration') &&
      account.usage_limits[:captain][:responses][:current_available].positive? &&
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.present?
  end

  def initialize(text:, account:)
    super()
    @text = text
    @account = account
  end

  def perform
    model = Llm::FeatureRouter.resolve(feature: 'call_announcement', account: account)[:model]
    audio = client.audio.speech(parameters: { model: model, input: text, voice: VOICE, response_format: 'mp3' })
    account.increment_response_usage
    audio
  end
end
