# frozen_string_literal: true

require 'seahorse/client/net_http/handler'

module Seahorse
  module Client
    module Plugins
      class NetHttp < Plugin

        option(:http_proxy, default: nil, doc_type: String, docstring: '')

        option(:http_open_timeout, default: 15, doc_type: Integer, docstring: '') do |cfg|
          resolve_http_open_timeout(cfg)
        end

        option(:http_read_timeout, default: 60, doc_type: Integer, docstring: '') do |cfg|
          resolve_http_read_timeout(cfg)
        end

        option(:http_idle_timeout, default: 5, doc_type: Integer, docstring: '')

        option(:http_continue_timeout, default: 1, doc_type: Integer, docstring: '')

        option(:http_wire_trace, default: false, doc_type: 'Boolean', docstring: '')

        option(:ssl_verify_peer, default: true, doc_type: 'Boolean', docstring: '')

        option(:ssl_ca_bundle, doc_type: String, docstring: '') do |cfg|
          ENV['AWS_CA_BUNDLE'] ||
            Aws.shared_config.ca_bundle(profile: cfg.profile) if cfg.respond_to?(:profile)
        end

        option(:ssl_ca_directory, default: nil, doc_type: String, docstring: '')

        option(:ssl_ca_store, default: nil, doc_type: String, docstring: '')

        option(:ssl_timeout, default: nil, doc_type: Float, docstring: '') do |cfg|
          resolve_ssl_timeout(cfg)
        end

        option(:logger) # for backwards compat

        handler(Client::NetHttp::Handler, step: :send)

        def self.resolve_http_open_timeout(cfg)
          default_mode_value =
            if cfg.respond_to?(:defaults_mode_config_resolver)
              cfg.defaults_mode_config_resolver.resolve(:http_open_timeout)
            end
          default_mode_value || 15
        end

        def self.resolve_http_read_timeout(cfg)
          default_mode_value =
            if cfg.respond_to?(:defaults_mode_config_resolver)
              cfg.defaults_mode_config_resolver.resolve(:http_read_timeout)
            end
          default_mode_value || 60
        end

        def self.resolve_ssl_timeout(cfg)
          default_mode_value =
            if cfg.respond_to?(:defaults_mode_config_resolver)
              cfg.defaults_mode_config_resolver.resolve(:ssl_timeout)
            end
          default_mode_value || nil
        end
      end
    end
  end
end
