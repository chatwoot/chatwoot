class MigrateCaptainFeaturePreferences < ActiveRecord::Migration[7.1]
  def up
    migrate_label_suggestion_from_hooks
    migrate_audio_transcriptions
  end

  def down
    # Revert captain_features['audio_transcription'] back to audio_transcriptions
    Account.find_each do |account|
      captain_features = account.settings['captain_features']
      next unless captain_features&.[]('audio_transcription') == true
      next if account.settings.key?('audio_transcriptions')

      account.settings = account.settings.merge('audio_transcriptions' => true)
      account.save(validate: false)
    end

    # NOTE: We cannot reliably revert label_suggestion back to OpenAI hook settings
  end

  private

  def migrate_label_suggestion_from_hooks
    Integrations::Hook.where(app_id: 'openai', status: :enabled).find_each do |hook|
      next unless hook.settings['label_suggestion'] == true

      account = Account.find_by(id: hook.account_id)
      next unless account

      update_captain_feature(account, 'label_suggestion', true)
    end
  end

  def migrate_audio_transcriptions
    Account.where.not("settings->>'audio_transcriptions' IS NULL").find_each do |account|
      next unless account.settings['audio_transcriptions'] == true

      update_captain_feature(account, 'audio_transcription', true)
    end
  end

  def update_captain_feature(account, feature_key, value)
    captain_features = account.settings['captain_features'] || {}
    return if captain_features.key?(feature_key)

    captain_features[feature_key] = value
    account.settings = account.settings.merge('captain_features' => captain_features)
    account.save(validate: false)
  end
end
