# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'grpc/server/chain'
require_relative 'grpc/server/rpc_server_prepend'
require_relative 'grpc/server/rpc_desc_prepend'

DependencyDetection.defer do
  named :grpc_server

  depends_on do
    defined?(GRPC) && defined?(GRPC::RpcServer) && defined?(GRPC::RpcDesc)
  end

  executes do
    supportability_name = NewRelic::Agent::Instrumentation::GRPC::Client::INSTRUMENTATION_NAME
    if use_prepend?
      prepend_instrument GRPC::RpcServer, NewRelic::Agent::Instrumentation::GRPC::Server::RpcServerPrepend, supportability_name
      prepend_instrument GRPC::RpcDesc, NewRelic::Agent::Instrumentation::GRPC::Server::RpcDescPrepend, supportability_name
    else
      chain_instrument NewRelic::Agent::Instrumentation::GRPC::Server::Chain, supportability_name
    end
  end
end
