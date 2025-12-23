# frozen_string_literal: true

require 'rack'

module Rack
  module Contrib
    def self.release
      require "git-version-bump"
      GVB.version
    rescue LoadError
      begin
        Gem::Specification.find_by_name("rack-contrib").version.to_s
      rescue Gem::LoadError
        "0.0.0.1.ENOGEM"
      end
    end
  end

  autoload :Access,                     "rack/contrib/access"
  autoload :BounceFavicon,              "rack/contrib/bounce_favicon"
  autoload :Cookies,                    "rack/contrib/cookies"
  autoload :CSSHTTPRequest,             "rack/contrib/csshttprequest"
  autoload :Deflect,                    "rack/contrib/deflect"
  autoload :EnforceValidEncoding,       "rack/contrib/enforce_valid_encoding"
  autoload :ExpectationCascade,         "rack/contrib/expectation_cascade"
  autoload :HostMeta,                   "rack/contrib/host_meta"
  autoload :GarbageCollector,           "rack/contrib/garbagecollector"
  autoload :JSONP,                      "rack/contrib/jsonp"
  autoload :JSONBodyParser,             "rack/contrib/json_body_parser"
  autoload :LazyConditionalGet,         "rack/contrib/lazy_conditional_get"
  autoload :LighttpdScriptNameFix,      "rack/contrib/lighttpd_script_name_fix"
  autoload :Locale,                     "rack/contrib/locale"
  autoload :MailExceptions,             "rack/contrib/mailexceptions"
  autoload :PostBodyContentTypeParser,  "rack/contrib/post_body_content_type_parser"
  autoload :ProcTitle,                  "rack/contrib/proctitle"
  autoload :Profiler,                   "rack/contrib/profiler"
  autoload :ResponseHeaders,            "rack/contrib/response_headers"
  autoload :Signals,                    "rack/contrib/signals"
  autoload :SimpleEndpoint,             "rack/contrib/simple_endpoint"
  autoload :TimeZone,                   "rack/contrib/time_zone"
  autoload :Evil,                       "rack/contrib/evil"
  autoload :Callbacks,                  "rack/contrib/callbacks"
  autoload :NestedParams,               "rack/contrib/nested_params"
  autoload :Config,                     "rack/contrib/config"
  autoload :NotFound,                   "rack/contrib/not_found"
  autoload :ResponseCache,              "rack/contrib/response_cache"
  autoload :RelativeRedirect,           "rack/contrib/relative_redirect"
  autoload :StaticCache,                "rack/contrib/static_cache"
  autoload :TryStatic,                  "rack/contrib/try_static"
  autoload :Printout,                   "rack/contrib/printout"
end
