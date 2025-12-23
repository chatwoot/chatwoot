# Copyright (C) 2010 Google Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

require "signet/version"

module Signet # :nodoc:
  def self.parse_auth_param_list auth_param_string
    # Production rules from:
    # http://tools.ietf.org/html/draft-ietf-httpbis-p1-messaging-12
    token = /[-!#{$OUTPUT_RECORD_SEPARATOR}%&'*+.^_`|~0-9a-zA-Z]+/
    d_qdtext = /[\s\x21\x23-\x5B\x5D-\x7E\x80-\xFF]/n
    d_quoted_pair = /\\[\s\x21-\x7E\x80-\xFF]/n
    d_qs = /"(?:#{d_qdtext}|#{d_quoted_pair})*"/
    # Production rules that allow for more liberal parsing, i.e. single quotes
    s_qdtext = /[\s\x21-\x26\x28-\x5B\x5D-\x7E\x80-\xFF]/n
    s_quoted_pair = /\\[\s\x21-\x7E\x80-\xFF]/n
    s_qs = /'(?:#{s_qdtext}|#{s_quoted_pair})*'/
    # Combine the above production rules to find valid auth-param pairs.
    auth_param = /((?:#{token})\s*=\s*(?:#{d_qs}|#{s_qs}|#{token}))/
    auth_param_pairs = []
    last_match = nil
    remainder = auth_param_string
    # Iterate over the string, consuming pair matches as we go.  Verify that
    # pre-matches and post-matches contain only allowable characters.
    #
    # This would be way easier in Ruby 1.9, but we want backwards
    # compatibility.
    while (match = remainder.match auth_param)
      if match.pre_match && match.pre_match !~ /^[\s,]*$/
        raise ParseError,
              "Unexpected auth param format: '#{auth_param_string}'."
      end
      auth_param_pairs << match.captures[0] # Appending pair
      remainder = match.post_match
      last_match = match
    end
    if last_match.post_match && last_match.post_match !~ /^[\s,]*$/
      raise ParseError,
            "Unexpected auth param format: '#{auth_param_string}'."
    end
    # Now parse the auth-param pair strings & turn them into key-value pairs.
    (auth_param_pairs.each_with_object [] do |pair, accu|
      name, value = pair.split "=", 2
      case value
      when /^".*"$/
        value = value.gsub(/^"(.*)"$/, '\1').gsub(/\\(.)/, '\1')
      when /^'.*'$/
        value = value.gsub(/^'(.*)'$/, '\1').gsub(/\\(.)/, '\1')
      when %r{[()<>@,;:\\"/\[\]?={}]}
        # Certain special characters are not allowed
        raise ParseError,
              "Unexpected characters in auth param " \
              "list: '#{auth_param_string}'."

      end
      accu << [name, value]
    end)
  end
end
