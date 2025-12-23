# frozen_string_literal: true

require 'singleton'

require 'addressable/uri'
require 'addressable/template'
require 'crack/xml'

require_relative 'webmock/deprecation'
require_relative 'webmock/version'

require_relative 'webmock/errors'

require_relative 'webmock/util/query_mapper'
require_relative 'webmock/util/uri'
require_relative 'webmock/util/headers'
require_relative 'webmock/util/hash_counter'
require_relative 'webmock/util/hash_keys_stringifier'
require_relative 'webmock/util/values_stringifier'
require_relative 'webmock/util/json'
require_relative 'webmock/util/version_checker'
require_relative 'webmock/util/hash_validator'

require_relative 'webmock/matchers/hash_argument_matcher'
require_relative 'webmock/matchers/hash_excluding_matcher'
require_relative 'webmock/matchers/hash_including_matcher'
require_relative 'webmock/matchers/any_arg_matcher'

require_relative 'webmock/request_pattern'
require_relative 'webmock/request_signature'
require_relative 'webmock/responses_sequence'
require_relative 'webmock/request_stub'
require_relative 'webmock/response'
require_relative 'webmock/rack_response'

require_relative 'webmock/stub_request_snippet'
require_relative 'webmock/request_signature_snippet'
require_relative 'webmock/request_body_diff'

require_relative 'webmock/assertion_failure'
require_relative 'webmock/request_execution_verifier'
require_relative 'webmock/config'
require_relative 'webmock/callback_registry'
require_relative 'webmock/request_registry'
require_relative 'webmock/stub_registry'
require_relative 'webmock/api'

require_relative 'webmock/http_lib_adapters/http_lib_adapter_registry'
require_relative 'webmock/http_lib_adapters/http_lib_adapter'
require_relative 'webmock/http_lib_adapters/net_http'
require_relative 'webmock/http_lib_adapters/http_rb_adapter'
require_relative 'webmock/http_lib_adapters/httpclient_adapter'
require_relative 'webmock/http_lib_adapters/patron_adapter'
require_relative 'webmock/http_lib_adapters/curb_adapter'
require_relative 'webmock/http_lib_adapters/em_http_request_adapter'
require_relative 'webmock/http_lib_adapters/typhoeus_hydra_adapter'
require_relative 'webmock/http_lib_adapters/excon_adapter'
require_relative 'webmock/http_lib_adapters/manticore_adapter'
require_relative 'webmock/http_lib_adapters/async_http_client_adapter'

require_relative 'webmock/webmock'
