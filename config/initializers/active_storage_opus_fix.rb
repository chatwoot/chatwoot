# Marcel identifies an Ogg Opus file as audio/opus, off the magic bytes `OggS` + `OpusHead`.
# That type names a codec rather than a container, and the container those bytes describe is
# Ogg, whose registered media type is audio/ogg (RFC 7845). Marcel's own table agrees: it lists
# audio/ogg as the parent type of audio/opus. So the detection is never wrong about the file,
# only about which of the two names to answer with, and the useful one is the container's.
#
# It has to be right before the object reaches storage. WhatsApp Cloud answers 131053
# "Unsupported Voice mime type audio/opus" to a voice note served as audio/opus (measured live:
# the same bytes served as audio/ogg are delivered and played), and on Google Cloud Storage what
# a reader gets is the Content-Type stored on the object itself — the response-content-type a
# signed URL carries is ignored whenever the object's own metadata sets one. That is why the
# reporter of #439 still saw the error after the blob column alone had been corrected.
#
# Both entry points, because they are two different paths and they take different arguments: a
# multipart upload unfurls the io and asks `extract_content_type`, while a direct upload is
# identified only once it is attached, through `identify_content_type`.
ActiveSupport.on_load(:active_storage_blob) do
  prepend(Module.new do
    private

    def extract_content_type(io)
      normalize_opus_content_type(super)
    end

    def identify_content_type
      normalize_opus_content_type(super)
    end

    def normalize_opus_content_type(detected)
      detected == 'audio/opus' ? 'audio/ogg' : detected
    end
  end)
end
