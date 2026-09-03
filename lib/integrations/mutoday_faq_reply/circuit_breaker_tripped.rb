# Synthetic. Nothing raises this — it exists so a tripped safety limit arrives in Sentry as
# its own class with its own grouping, rather than as a log line nobody reads. A tripped
# breaker means a loop is loose and a real customer's phone is at risk.
class Integrations::MutodayFaqReply::CircuitBreakerTripped < StandardError; end
