# frozen_string_literal: true

Sentry.register_patch(:graphql) do |config|
  if defined?(::GraphQL::Schema) && defined?(::GraphQL::Tracing::SentryTrace) && ::GraphQL::Schema.respond_to?(:trace_with)
    ::GraphQL::Schema.trace_with(::GraphQL::Tracing::SentryTrace, set_transaction_name: true)
  else
    config.logger.warn(Sentry::LOGGER_PROGNAME) { 'You tried to enable the GraphQL integration but no GraphQL gem was detected. Make sure you have the `graphql` gem (>= 2.2.6) in your Gemfile.' }
  end
end
