# -*- ruby -*-
# frozen_string_literal: true

module PG
	module BinaryEncoder
		# Convenience classes for timezone options
		class TimestampUtc < Timestamp
			def initialize(hash={}, **kwargs)
				warn("PG::Coder.new(hash) is deprecated. Please use keyword arguments instead! Called from #{caller.first}", category: :deprecated) unless hash.empty?
				super(**hash, **kwargs, flags: PG::Coder::TIMESTAMP_DB_UTC)
			end
		end
		class TimestampLocal < Timestamp
			def initialize(hash={}, **kwargs)
				warn("PG::Coder.new(hash) is deprecated. Please use keyword arguments instead! Called from #{caller.first}", category: :deprecated) unless hash.empty?
				super(**hash, **kwargs, flags: PG::Coder::TIMESTAMP_DB_LOCAL)
			end
		end
	end
end # module PG
