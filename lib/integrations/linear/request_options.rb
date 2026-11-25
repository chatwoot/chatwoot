# Every HTTParty call to Linear, with the number and the reason it is that number.
#
# One ceiling for the four, because they all wait on the same thing: Linear answering out
# of its own state. Two of them exchange a token, one revokes it and one is the GraphQL
# endpoint every issue action goes through. None of them hands Linear a body to go fetch,
# which is what would justify waiting longer.
#
# Fifteen and not ten because the GraphQL one is in the group: an agent clicked something
# in the dashboard and is waiting on the issue to exist, and a query that reads a team's
# issues is more work for Linear than handing back a token.
#
# `max_retries: 0`: `Net::HTTP` repeats an idempotent request once by default, and on a
# token exchange a silent second attempt is a second token.
module Integrations::Linear::RequestOptions
  LINEAR_REQUEST_OPTIONS = { timeout: 15, max_retries: 0 }.freeze
end
