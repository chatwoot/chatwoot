# Marcel gem may detect OGG Opus files as audio/opus instead of audio/ogg.
# This is problematic because WhatsApp Cloud API (and other services)
# expect audio/ogg for OGG container files with the Opus codec.
#
# This initializer patches ActiveStorage::Blob to normalize audio/opus → audio/ogg
# at identification time for .ogg files, preventing the wrong content_type from
# being persisted. Files with .opus extension are left as audio/opus since they
# are genuinely Opus-only files.
ActiveSupport.on_load(:active_storage_blob) do
  prepend(Module.new do
    private

    def identify_content_type(io = nil)
      detected = super
      detected == 'audio/opus' && filename.to_s.end_with?('.ogg') ? 'audio/ogg' : detected
    end
  end)
end
