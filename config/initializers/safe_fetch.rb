# fazer-ai/chatwoot#927: a SAFE_FETCH_PRIVATE_TARGETS entry without a port fails the boot instead of the first fetch.
Rails.application.config.after_initialize { SafeFetch.private_targets }
