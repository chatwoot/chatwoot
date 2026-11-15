# Per-inbox call settings kept in provider_config, shared by every channel that can place calls.
# Both default on, so inboxes that predate the setting keep recording and transcribing.
# A plain module (no ActiveSupport::Concern) so it can be included into a prepended Enterprise module.
module Concerns::CallRecordingSettings
  def recording_enabled?
    provider_config['recording_enabled'] != false
  end

  # Only reached when a recording exists, which already implies recording was on for that call.
  def transcription_enabled?
    provider_config['transcription_enabled'] != false
  end
end
