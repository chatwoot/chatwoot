# Meta accepts the connection and can then stay quiet. Without a ceiling, one request occupies a
# Puma thread for as long as Meta feels like staying quiet, and nothing in the app ever decides to
# stop waiting.
#
# There are two axes here and a ceiling alone only closes the first. `Net::HTTP` retries an
# idempotent request once by default, so a read costs twice the ceiling while a write costs it once.
# Measured against a socket that accepts the connection and never answers:
#
#   GET  timeout: 5                    10.0s
#   GET  timeout: 5, max_retries: 0     5.0s
#   POST timeout: 5                     5.0s
#
# The value is 10s because that is what the Baileys provider in this repo already uses for the same
# kind of call, and because the failure of a ceiling that is too low is not a slow page: it is the
# health screen reporting "could not read the routing" for a Meta that was going to answer. That
# screen exists to stop false reassurance, so inventing a false alarm in its place is not a trade
# worth making.
module Whatsapp::GraphRequestOptions
  GRAPH_REQUEST_OPTIONS = { timeout: 10, max_retries: 0 }.freeze
end
