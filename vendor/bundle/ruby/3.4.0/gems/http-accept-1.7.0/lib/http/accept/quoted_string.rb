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

module HTTP
	module Accept
		# According to https://tools.ietf.org/html/rfc7231#appendix-C
		TOKEN = /[!#$%&'*+\-.^_`|~0-9A-Z]+/i
		QUOTED_STRING = /"(?:.(?!(?<!\\)"))*.?"/
		
		module QuotedString
			# Unquote a "quoted-string" value according to https://tools.ietf.org/html/rfc7230#section-3.2.6
			# It should already match the QUOTED_STRING pattern above by the parser.
			def self.unquote(value, normalize_whitespace = true)
				value = value[1...-1]
				
				value.gsub!(/\\(.)/, '\1') 
				
				if normalize_whitespace
					# LWS = [CRLF] 1*( SP | HT )
					value.gsub!(/[\r\n]+\s+/, ' ')
				end
				
				return value
			end
			
			# Quote a string if required. Doesn't handle newlines correctly currently.
			def self.quote(value, force = false)
				if value =~ /"/ or force
					"\"#{value.gsub(/["\\]/, "\\\\\\0")}\""
				else
					return value
				end
			end
		end
	end
end
