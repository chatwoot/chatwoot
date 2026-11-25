# Every HTTParty call to the TikTok Business API, plus the one that does not go through
# HTTParty at all, with the numbers and the reason each one is what it is.
#
# `max_retries: 0`: `Net::HTTP` repeats an idempotent request once by default, and three
# of these eight are GETs, so their ceiling was worth half of what it read as.
#
# One ceiling for the eight, unlike the channels that send media by URL. TikTok never
# fetches anything from us while answering: an image is uploaded first, separately, and
# the send then names it by `media_id`. So every one of these eight answers out of
# TikTok's own state, and none of them has a reason to wait longer than the others.
module Tiktok::RequestOptions
  TIKTOK_REQUEST_OPTIONS = { timeout: 10, max_retries: 0 }.freeze

  # The upload is the exception, and it is the only call here that carries bytes: it is a
  # multipart POST over Faraday, which defaults to no ceiling at all, so a TikTok that
  # accepted the connection and stopped reading held the worker until the socket died on
  # its own. Faraday names the same two things separately, and it has no retry of its own
  # to close.
  TIKTOK_UPLOAD_TIMEOUT = 120
  TIKTOK_OPEN_TIMEOUT = 10
end
