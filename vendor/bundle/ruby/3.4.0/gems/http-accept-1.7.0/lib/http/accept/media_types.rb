# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'strscan'

require_relative 'parse_error'
require_relative 'quoted_string'
require_relative 'sort'

require_relative 'media_types/map'

module HTTP
	module Accept
		# Parse and process the HTTP Accept: header.
		module MediaTypes
			# According to https://tools.ietf.org/html/rfc7231#section-5.3.2
			MIME_TYPE = /(#{TOKEN})\/(#{TOKEN})/
			PARAMETER = /\s*;\s*(?<key>#{TOKEN})=((?<value>#{TOKEN})|(?<quoted_value>#{QUOTED_STRING}))/
			
			# A single entry in the Accept: header, which includes a mime type and associated parameters.
			MediaRange = Struct.new(:mime_type, :parameters) do
				def parameters_string
					return '' if parameters == nil or parameters.empty?
					
					parameters.collect do |key, value|
						"; #{key.to_s}=#{QuotedString.quote(value.to_s)}"
					end.join
				end
				
				def === other
					if other.is_a? self.class
						super
					else
						return self.mime_type === other
					end
				end
				
				def to_s
					"#{mime_type}#{parameters_string}"
				end
				
				alias to_str to_s
				
				def quality_factor
					parameters.fetch('q', 1.0).to_f
				end
				
				def split(on = '/', count = 2)
					mime_type.split(on, count)
				end
				
				def self.parse_parameters(scanner, normalize_whitespace)
					parameters = {}
					
					while scanner.scan(PARAMETER)
						key = scanner[:key]
						
						# If the regular expression PARAMETER matched, it must be one of these two:
						if value = scanner[:value]
							parameters[key] = value
						elsif quoted_value = scanner[:quoted_value]
							parameters[key] = QuotedString.unquote(quoted_value, normalize_whitespace)
						end
					end
					
					return parameters
				end
				
				def self.parse(scanner, normalize_whitespace = true)
					return to_enum(:parse, scanner, normalize_whitespace) unless block_given?
					
					while mime_type = scanner.scan(MIME_TYPE)
						parameters = parse_parameters(scanner, normalize_whitespace)
						
						yield self.new(mime_type, parameters)
						
						# Are there more?
						break unless scanner.scan(/\s*,\s*/)
					end
					
					raise ParseError.new("Could not parse entire string!") unless scanner.eos?
				end
			end
			
			def self.parse(text, normalize_whitespace = true)
				scanner = StringScanner.new(text)
				
				media_types = MediaRange.parse(scanner, normalize_whitespace)
				
				return Sort.by_quality_factor(media_types)
			end
			
			HTTP_ACCEPT = 'HTTP_ACCEPT'.freeze
			WILDCARD_MEDIA_RANGE = MediaRange.new("*/*", {}).freeze
			
			# Parse the list of browser preferred content types and return ordered by priority. If no `Accept:` header is specified, the behaviour is the same as if `Accept: */*` was provided (according to RFC).
			def self.browser_preferred_media_types(env)
				if accept_content_types = env[HTTP_ACCEPT]
					accept_content_types.strip!
					
					unless accept_content_types.empty?
						return HTTP::Accept::MediaTypes.parse(accept_content_types)
					end
				end
				
				# According to http://tools.ietf.org/html/rfc7231#section-5.3.2:
				# A request without any Accept header field implies that the user agent will accept any media type in response.
				# You should treat a non-existent Accept header as */*.
				return [WILDCARD_MEDIA_RANGE]
			end
		end
	end
end

