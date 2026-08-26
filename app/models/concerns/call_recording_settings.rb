# Per-inbox call recording flags kept in provider_config. Both default on; only an explicit false disables.
module CallRecordingSettings
  extend ActiveSupport::Concern

  def recording_enabled?
    provider_config['recording_enabled'] != false
  end

  # A recording only exists when recording was on, so callers need not re-check recording_enabled?.
  def transcription_enabled?
    provider_config['transcription_enabled'] != false
  end
end
