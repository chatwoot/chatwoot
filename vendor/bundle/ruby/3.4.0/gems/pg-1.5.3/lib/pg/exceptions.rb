# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )


module PG

	class Error < StandardError
		def initialize(msg=nil, connection: nil, result: nil)
			@connection = connection
			@result = result
			super(msg)
		end
	end

	class NotAllCopyDataRetrieved < PG::Error
	end
	class LostCopyState < PG::Error
	end
	class NotInBlockingMode < PG::Error
	end

end # module PG

