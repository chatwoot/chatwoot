# frozen_string_literal: true

require 'seahorse/client/h2/handler'

module Seahorse
  module Client
    module Plugins
      class H2 < Plugin

        # H2 Client
        option(:max_concurrent_streams, default: 100, doc_type: Integer, docstring: <<-DOCS)
Maximum concurrent streams used in HTTP2 connection, defaults to 100. Note that server may send back
:settings_max_concurrent_streams value which will take priority when initializing new streams.
        DOCS

        option(:connection_timeout, default: 60, doc_type: Integer, docstring: <<-DOCS)
Connection timeout in seconds, defaults to 60 sec.
        DOCS

        option(:connection_read_timeout, default: 60, doc_type: Integer, docstring: <<-DOCS)
Connection read timeout in seconds, defaults to 60 sec.
        DOCS

        option(:read_chunk_size, default: 1024, doc_type: Integer, docstring: '')

        option(:raise_response_errors, default: true, doc_type: 'Boolean', docstring: <<-DOCS)
Defaults to `true`, raises errors if exist when #wait or #join! is called upon async response.
        DOCS

        # SSL Context
        option(:ssl_ca_bundle, default: nil, doc_type: String, docstring: <<-DOCS) do |cfg|
Full path to the SSL certificate authority bundle file that should be used when
verifying peer certificates. If you do not pass `:ssl_ca_directory` or `:ssl_ca_bundle`
the system default will be used if available.
        DOCS
          ENV['AWS_CA_BUNDLE'] ||
            Aws.shared_config.ca_bundle(profile: cfg.profile) if cfg.respond_to?(:profile)
        end

        option(:ssl_ca_directory, default: nil, doc_type: String, docstring: <<-DOCS)
Full path of the directory that contains the unbundled SSL certificate authority
files for verifying peer certificates. If you do not pass `:ssl_ca_bundle` or
`:ssl_ca_directory` the system default will be used if available.
        DOCS

        option(:ssl_ca_store, default: nil, doc_type: String, docstring: '')

        option(:ssl_verify_peer, default: true, doc_type: 'Boolean', docstring: <<-DOCS)
When `true`, SSL peer certificates are verified when establishing a connection.
        DOCS

        option(:http_wire_trace, default: false, doc_type:  'Boolean', docstring: <<-DOCS)
When `true`, HTTP2 debug output will be sent to the `:logger`.
        DOCS

        option(:enable_alpn, default: false, doc_type: 'Boolean', docstring: <<-DOCS)
Set to `true` to enable ALPN in HTTP2 over TLS. Requires Openssl version >= 1.0.2.
Defaults to false. Note: not all service HTTP2 operations supports ALPN on server
side, please refer to service documentation.
        DOCS

        option(:logger)

        handler(Client::H2::Handler, step: :send)

      end
    end
  end
end
