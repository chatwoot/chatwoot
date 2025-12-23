# frozen_string_literal: true

# Copyright (C) 2007-2019 Leah Neukirchen <http://leahneukirchen.org/infopage.html>
#
# Rack is freely distributable under the terms of an MIT-style license.
# See MIT-LICENSE or https://opensource.org/licenses/MIT.

# The Rack main module, serving as a namespace for all core Rack
# modules and classes.
#
# All modules meant for use in your application are <tt>autoload</tt>ed here,
# so it should be enough just to <tt>require 'rack'</tt> in your code.

require_relative 'rack/version'
require_relative 'rack/constants'

module Rack
  autoload :BadRequest, "rack/bad_request"
  autoload :BodyProxy, "rack/body_proxy"
  autoload :Builder, "rack/builder"
  autoload :Cascade, "rack/cascade"
  autoload :CommonLogger, "rack/common_logger"
  autoload :ConditionalGet, "rack/conditional_get"
  autoload :Config, "rack/config"
  autoload :ContentLength, "rack/content_length"
  autoload :ContentType, "rack/content_type"
  autoload :Deflater, "rack/deflater"
  autoload :Directory, "rack/directory"
  autoload :ETag, "rack/etag"
  autoload :Events, "rack/events"
  autoload :Files, "rack/files"
  autoload :ForwardRequest, "rack/recursive"
  autoload :Head, "rack/head"
  autoload :Headers, "rack/headers"
  autoload :Lint, "rack/lint"
  autoload :Lock, "rack/lock"
  autoload :MediaType, "rack/media_type"
  autoload :MethodOverride, "rack/method_override"
  autoload :Mime, "rack/mime"
  autoload :MockRequest, "rack/mock_request"
  autoload :MockResponse, "rack/mock_response"
  autoload :Multipart, "rack/multipart"
  autoload :NullLogger, "rack/null_logger"
  autoload :QueryParser, "rack/query_parser"
  autoload :Recursive, "rack/recursive"
  autoload :Reloader, "rack/reloader"
  autoload :Request, "rack/request"
  autoload :Response, "rack/response"
  autoload :RewindableInput, "rack/rewindable_input"
  autoload :Runtime, "rack/runtime"
  autoload :Sendfile, "rack/sendfile"
  autoload :ShowExceptions, "rack/show_exceptions"
  autoload :ShowStatus, "rack/show_status"
  autoload :Static, "rack/static"
  autoload :TempfileReaper, "rack/tempfile_reaper"
  autoload :URLMap, "rack/urlmap"
  autoload :Utils, "rack/utils"

  module Auth
    autoload :Basic, "rack/auth/basic"
    autoload :AbstractHandler, "rack/auth/abstract/handler"
    autoload :AbstractRequest, "rack/auth/abstract/request"
  end
end
