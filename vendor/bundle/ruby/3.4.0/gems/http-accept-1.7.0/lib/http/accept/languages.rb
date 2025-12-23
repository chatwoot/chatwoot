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
require_relative 'sort'

module HTTP
	module Accept
		module Languages
			# https://tools.ietf.org/html/rfc3066#section-2.1
			LOCALE = /\*|[A-Z]{1,8}(-[A-Z0-9]{1,8})*/i
			
			# https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.9
			QVALUE = /0(\.[0-9]{0,3})?|1(\.[0]{0,3})?/
			
			# https://greenbytes.de/tech/webdav/rfc7231.html#quality.values
			LANGUAGE_RANGE = /(?<locale>#{LOCALE})(\s*;\s*q=(?<q>#{QVALUE}))?/
			
			# Provides an efficient data-structure for matching the Accept-Languages header to set of available locales according to https://tools.ietf.org/html/rfc7231#section-5.3.5 and https://tools.ietf.org/html/rfc4647#section-2.3
			class Locales
				def self.expand(locale, into)
					parts = locale.split('-')
					
					while parts.size > 0
						key = parts.join('-')
						
						into[key] ||= locale
						
						parts.pop
					end
				end
				
				def initialize(names)
					@names = names
					@patterns = {}
					
					@names.each{|name| self.class.expand(name, @patterns)}
					
					self.freeze
				end
				
				def freeze
					@names.freeze
					@patterns.freeze
					
					super
				end
				
				def each(&block)
					return to_enum unless block_given?
					
					@names.each(&block)
				end
				
				attr :names
				attr :patterns
				
				# Returns the intersection of others retaining order.
				def & languages
					languages.collect{|language_range| @patterns[language_range.locale]}.compact
				end
				
				def include? locale_name
					@patterns.include? locale_name
				end
				
				def join(*args)
					@names.join(*args)
				end
				
				def + others
					self.class.new(@names + others.to_a)
				end
				
				def to_a
					@names
				end
			end
			
			LanguageRange = Struct.new(:locale, :q) do
				def quality_factor
					(q || 1.0).to_f
				end
				
				def self.parse(scanner)
					return to_enum(:parse, scanner) unless block_given?
					
					while scanner.scan(LANGUAGE_RANGE)
						yield self.new(scanner[:locale], scanner[:q])
						
						# Are there more?
						break unless scanner.scan(/\s*,\s*/)
					end
					
					raise ParseError.new("Could not parse entire string!") unless scanner.eos?
				end
			end
			
			def self.parse(text)
				scanner = StringScanner.new(text)
				
				languages = LanguageRange.parse(scanner)
				
				return Sort.by_quality_factor(languages)
			end
		end
	end
end
