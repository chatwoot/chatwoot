# One ceiling for 360dialog, and one is enough because its bodies are all the same size class.
#
# It is a BSP in front of Meta's Cloud API, and `send_attachment_message` passes a `link` rather
# than the file: no call in this provider carries media in the body. So every request here is a
# small JSON document answered by the same upstream the Graph family talks to directly, whose
# ceiling this repo already chose and wrote down in Whatsapp::GraphRequestOptions. The extra hop
# is 360dialog's own, and it is not the part that stalls.
#
# `max_retries: 0` for the reason the other families carry it: `Net::HTTP` retries an idempotent
# request once by default, so the template sync GET cost twice what its ceiling said.
module Whatsapp::Dialog360RequestOptions
  DIALOG360_REQUEST_OPTIONS = { timeout: 10, max_retries: 0 }.freeze
end
