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
		module Charsets
			# https://tools.ietf.org/html/rfc7231#section-5.3.1
			QVALUE = /0(\.[0-9]{0,3})?|1(\.[0]{0,3})?/
			
			# https://tools.ietf.org/html/rfc7231#section-5.3.3
			CHARSETS = /(?<charset>#{TOKEN})(;q=(?<q>#{QVALUE}))?/
			
			Charset = Struct.new(:charset, :q) do
				def quality_factor
					(q || 1.0).to_f
				end
				
				def self.parse(scanner)
					return to_enum(:parse, scanner) unless block_given?
					
					while scanner.scan(CHARSETS)
						yield self.new(scanner[:charset], scanner[:q])
						
						# Are there more?
						break unless scanner.scan(/\s*,\s*/)
					end
					
					raise ParseError.new('Could not parse entire string!') unless scanner.eos?
				end
			end
			
			def self.parse(text)
				scanner = StringScanner.new(text)
				
				charsets = Charset.parse(scanner)
				
				return Sort.by_quality_factor(charsets)
			end
			
			HTTP_ACCEPT_CHARSET = 'HTTP_ACCEPT_CHARSET'.freeze
			WILDCARD_CHARSET = Charset.new('*', nil).freeze
			
			# Parse the list of browser preferred charsets and return ordered by priority.
			def self.browser_preferred_charsets(env)
				if accept_charsets = env[HTTP_ACCEPT_CHARSET]
					accept_charsets.strip!
					
					if accept_charsets.empty?
						# https://tools.ietf.org/html/rfc7231#section-5.3.3 :
						#
						#    Accept-Charset = 1#( ( charset / "*" ) [ weight ] )
						#
						# Because of the `1#` rule, an empty header value is not considered valid.
						raise ParseError.new('Could not parse entire string!')
					else
						return HTTP::Accept::Charsets.parse(accept_charsets)
					end
				end
				
				# "A request without any Accept-Charset header field implies that the
				#  user agent will accept any charset in response."
				return [WILDCARD_CHARSET]
			end
		end
	end
end
