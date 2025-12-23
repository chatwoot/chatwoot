# -*- ruby -*-
# frozen_string_literal: true

require 'json'

module PG
	module TextDecoder
		class JSON < SimpleDecoder
			def decode(string, tuple=nil, field=nil)
				::JSON.parse(string, quirks_mode: true)
			end
		end
	end
end # module PG
