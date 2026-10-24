# Webhook delivery failures

Account webhooks and API inbox callbacks retry HTTP 429 and 5xx responses, as
well as transient connection and read/open timeout failures. There are at most
three delivery attempts, with a three-second base retry delay. Retry scheduling
uses ActiveJob; it does not hold the request or sleep in the worker.

A successful attempt ends the sequence. An API inbox message is marked failed
only when all attempts fail, or immediately for a non-retryable failure. URL
validation/SSRF rejection, certificate verification errors, and other 4xx
responses are not retried. The existing AgentBot policy remains unchanged:
429 and 500 are retried, with its configured failure handling after exhaustion.

A retry retains the queued payload and `X-Chatwoot-Delivery` identifier. The
`X-Chatwoot-Timestamp` and body signature are generated anew on each attempt.
Consumers should verify each signature, de-duplicate deliveries and acknowledge
only after accepting the event into a durable queue. A timeout can mean that a
receiver processed an event but its response was lost; retries can therefore
produce duplicates. This is not an exactly-once delivery guarantee.

`WEBHOOK_TIMEOUT` is an installation configuration (managed through Super Admin),
not an environment variable. It defaults to five seconds and sets both connection
and read timeouts for each request. Increasing it is not a substitute for durable
receiver-side ingestion. Queue/process failure recovery and re-driving deliveries
after the final attempt are separate operational concerns.
