# frozen_string_literal: true

require_relative 'constants'
require_relative 'utils'
require_relative 'body_proxy'

module Rack

  # Middleware that enables conditional GET using if-none-match and
  # if-modified-since. The application should set either or both of the
  # last-modified or etag response headers according to RFC 2616. When
  # either of the conditions is met, the response body is set to be zero
  # length and the response status is set to 304 Not Modified.
  #
  # Applications that defer response body generation until the body's each
  # message is received will avoid response body generation completely when
  # a conditional GET matches.
  #
  # Adapted from Michael Klishin's Merb implementation:
  # https://github.com/wycats/merb/blob/master/merb-core/lib/merb-core/rack/middleware/conditional_get.rb
  class ConditionalGet
    def initialize(app)
      @app = app
    end

    # Return empty 304 response if the response has not been
    # modified since the last request.
    def call(env)
      case env[REQUEST_METHOD]
      when "GET", "HEAD"
        status, headers, body = response = @app.call(env)

        if status == 200 && fresh?(env, headers)
          response[0] = 304
          headers.delete(CONTENT_TYPE)
          headers.delete(CONTENT_LENGTH)

          # We are done with the body:
          body.close if body.respond_to?(:close)
          response[2] = []
        end
        response
      else
        @app.call(env)
      end
    end

  private

    # Return whether the response has not been modified since the
    # last request.
    def fresh?(env, headers)
      # if-none-match has priority over if-modified-since per RFC 7232
      if none_match = env['HTTP_IF_NONE_MATCH']
        etag_matches?(none_match, headers)
      elsif (modified_since = env['HTTP_IF_MODIFIED_SINCE']) && (modified_since = to_rfc2822(modified_since))
        modified_since?(modified_since, headers)
      end
    end

    # Whether the etag response header matches the if-none-match request header.
    # If so, the request has not been modified.
    def etag_matches?(none_match, headers)
      headers[ETAG] == none_match
    end

    # Whether the last-modified response header matches the if-modified-since
    # request header.  If so, the request has not been modified.
    def modified_since?(modified_since, headers)
      last_modified = to_rfc2822(headers['last-modified']) and
        modified_since >= last_modified
    end

    # Return a Time object for the given string (which should be in RFC2822
    # format), or nil if the string cannot be parsed.
    def to_rfc2822(since)
      # shortest possible valid date is the obsolete: 1 Nov 97 09:55 A
      # anything shorter is invalid, this avoids exceptions for common cases
      # most common being the empty string
      if since && since.length >= 16
        # NOTE: there is no trivial way to write this in a non exception way
        #   _rfc2822 returns a hash but is not that usable
        Time.rfc2822(since) rescue nil
      end
    end
  end
end
