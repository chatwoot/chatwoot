# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'grpc/client/chain'
require_relative 'grpc/client/prepend'

DependencyDetection.defer do
  named :grpc_client

  depends_on do
    defined?(GRPC) && defined?(GRPC::ClientStub)
  end

  executes do
    supportability_name = NewRelic::Agent::Instrumentation::GRPC::Client::INSTRUMENTATION_NAME
    if use_prepend?
      prepend_instrument GRPC::ClientStub, NewRelic::Agent::Instrumentation::GRPC::Client::Prepend, supportability_name
    else
      chain_instrument NewRelic::Agent::Instrumentation::GRPC::Client::Chain, supportability_name
    end
  end
end
