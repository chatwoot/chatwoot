# frozen_string_literal: true

require_relative '../tracing'
require_relative 'contrib/registry'
require_relative 'contrib/extensions'

module Datadog
  module Tracing
    module Contrib
      # Registry is a global, declarative repository of all available integrations.
      #
      # Integrations should register themselves with the registry as early as
      # possible as the initial tracer configuration can only activate integrations
      # if they have already been registered.
      #
      # Despite that, integrations *can* be appended to the registry at any point
      # of the program execution. Newly appended integrations can then be
      # activated during tracer reconfiguration.
      #
      # The registry does not depend on runtime configuration and registered integrations
      # must execute correctly after successive configuration changes.
      # The registered integrations themselves can depend on the stateful configuration
      # of the tracer.
      #
      # `Datadog.registry` is a helper accessor to this constant, but it's only available
      # after the tracer has complete initialization. Use `Datadog::Tracing::Contrib::REGISTRY` instead
      # of `Datadog.registry` when you code might be called during tracer initialization.
      REGISTRY = Registry.new
    end
  end
end

require_relative 'contrib/action_cable/integration'
require_relative 'contrib/action_mailer/integration'
require_relative 'contrib/action_pack/integration'
require_relative 'contrib/action_view/integration'
require_relative 'contrib/active_model_serializers/integration'
require_relative 'contrib/active_job/integration'
require_relative 'contrib/active_record/integration'
require_relative 'contrib/active_support/integration'
require_relative 'contrib/aws/integration'
require_relative 'contrib/concurrent_ruby/integration'
require_relative 'contrib/dalli/integration'
require_relative 'contrib/delayed_job/integration'
require_relative 'contrib/elasticsearch/integration'
require_relative 'contrib/ethon/integration'
require_relative 'contrib/excon/integration'
require_relative 'contrib/faraday/integration'
require_relative 'contrib/grape/integration'
require_relative 'contrib/graphql/integration'
require_relative 'contrib/grpc'
require_relative 'contrib/hanami/integration'
require_relative 'contrib/http'
require_relative 'contrib/httpclient/integration'
require_relative 'contrib/httprb/integration'
require_relative 'contrib/integration'
require_relative 'contrib/kafka/integration'
require_relative 'contrib/karafka'
require_relative 'contrib/lograge/integration'
require_relative 'contrib/mongodb/integration'
require_relative 'contrib/mysql2/integration'
require_relative 'contrib/opensearch/integration'
require_relative 'contrib/pg/integration'
require_relative 'contrib/presto/integration'
require_relative 'contrib/que/integration'
require_relative 'contrib/racecar/integration'
require_relative 'contrib/rack/integration'
require_relative 'contrib/rails/integration'
require_relative 'contrib/rake/integration'
require_relative 'contrib/redis/integration'
require_relative 'contrib/resque/integration'
require_relative 'contrib/rest_client/integration'
require_relative 'contrib/roda/integration'
require_relative 'contrib/semantic_logger/integration'
require_relative 'contrib/sequel/integration'
require_relative 'contrib/shoryuken/integration'
require_relative 'contrib/sidekiq'
require_relative 'contrib/sinatra/integration'
require_relative 'contrib/sneakers/integration'
require_relative 'contrib/stripe/integration'
require_relative 'contrib/sucker_punch/integration'
require_relative 'contrib/trilogy/integration'
