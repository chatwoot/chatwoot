class FixOldAudioAlertData < ActiveRecord::Migration[7.0]
  def change
    # rubocop:disable Rails/SkipsModelValidations

    # Update users with audio alerts enabled to 'mine'
    User.where(
      "users.ui_settings #>> '{enable_audio_alerts}' = ?", 'true'
    ).update_all(
      "ui_settings = jsonb_set(ui_settings, '{enable_audio_alerts}', '\"mine\"')"
    )

    # Update users with audio alerts enabled to 'none'
    User
      .where("users.ui_settings #>> '{enable_audio_alerts}' = ?", 'true')
      .update_all("ui_settings = jsonb_set(ui_settings, '{enable_audio_alerts}', '\"mine\"')")
    # rubocop:enable Rails/SkipsModelValidations
  end
end
