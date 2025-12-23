# Copyright (C) 2016, Matthew Kerwin <matthew@kerwin.net.au>
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

module HTTP
	module Accept
		module Encodings
			# https://tools.ietf.org/html/rfc7231#section-5.3.4
			CONTENT_CODING = TOKEN
			
			# https://tools.ietf.org/html/rfc7231#section-5.3.1
			QVALUE = /0(\.[0-9]{0,3})?|1(\.[0]{0,3})?/
			
			CODINGS = /(?<encoding>#{CONTENT_CODING})(;q=(?<q>#{QVALUE}))?/
			
			ContentCoding = Struct.new(:encoding, :q) do
				def quality_factor
					(q || 1.0).to_f
				end
				
				def self.parse(scanner)
					return to_enum(:parse, scanner) unless block_given?
					
					while scanner.scan(CODINGS)
						yield self.new(scanner[:encoding], scanner[:q])
						
						# Are there more?
						break unless scanner.scan(/\s*,\s*/)
					end
					
					raise ParseError.new('Could not parse entire string!') unless scanner.eos?
				end
			end
			
			def self.parse(text)
				scanner = StringScanner.new(text)
				
				encodings = ContentCoding.parse(scanner)
				
				return Sort.by_quality_factor(encodings)
			end
			
			HTTP_ACCEPT_ENCODING = 'HTTP_ACCEPT_ENCODING'.freeze
			WILDCARD_CONTENT_CODING = ContentCoding.new('*', nil).freeze
			IDENTITY_CONTENT_CODING = ContentCoding.new('identity', nil).freeze
			
			# Parse the list of browser preferred content codings and return ordered by priority. If no
			# `Accept-Encoding:` header is specified, the behaviour is the same as if
			# `Accept-Encoding: *` was provided, and if a blank `Accept-Encoding:` header value is
			# specified, the behaviour is the same as if `Accept-Encoding: identity` was provided
			# (according to RFC).
			def self.browser_preferred_content_codings(env)
				if accept_content_codings = env[HTTP_ACCEPT_ENCODING]
					accept_content_codings.strip!
					
					if accept_content_codings.empty?
						# "An Accept-Encoding header field with a combined field-value that is
						# empty implies that the user agent does not want any content-coding in
						# response."
						return [IDENTITY_CONTENT_CODING]
					else
						return HTTP::Accept::Encodings.parse(accept_content_codings)
					end
				end
				
				# "If no Accept-Encoding field is in the request, any content-coding
				#  is considered acceptable by the user agent."
				return [WILDCARD_CONTENT_CODING]
			end
		end
	end
end
