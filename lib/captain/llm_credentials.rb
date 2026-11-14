# Picks the API key for a task's request: the installation key for the model's provider,
# or the account's OpenAI integration key for tasks that opt into it.
module Captain::LlmCredentials
  extend ActiveSupport::Concern

  private

  def api_key_configured?
    llm_credential.present?
  end

  def api_key
    llm_credential&.dig(:api_key)
  end

  def llm_provider
    @llm_provider || 'openai'
  end

  def llm_credential
    return anthropic_llm_credential if llm_provider == 'anthropic'

    @llm_credential ||= if use_account_openai_hook?
                          hook_llm_credential || system_llm_credential
                        else
                          system_llm_credential
                        end
  end

  def use_account_openai_hook?
    false
  end

  def hook_llm_credential
    key = openai_hook&.settings&.dig('api_key').presence
    { api_key: key, source: :hook } if key
  end

  def system_llm_credential
    { api_key: system_api_key, source: :system } if system_api_key.present?
  end

  def anthropic_llm_credential
    api_key = Llm::Config.api_key_for('anthropic')
    { api_key: api_key, source: :system } if api_key
  end

  def openai_hook
    @openai_hook ||= account.hooks.find_by(app_id: 'openai', status: 'enabled')
  end

  def system_api_key
    @system_api_key ||= InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  end
end
