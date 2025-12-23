# -*- ruby -*-
# frozen_string_literal: true

require 'date'

module PG
	module TextDecoder
		class Date < SimpleDecoder
			def decode(string, tuple=nil, field=nil)
				if string =~ /\A(\d{4})-(\d\d)-(\d\d)\z/
					::Date.new $1.to_i, $2.to_i, $3.to_i
				else
					string
				end
			end
		end
	end
end # module PG
