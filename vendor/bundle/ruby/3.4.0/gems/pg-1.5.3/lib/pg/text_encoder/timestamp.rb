# -*- ruby -*-
# frozen_string_literal: true

module PG
	module TextEncoder
		class TimestampWithoutTimeZone < SimpleEncoder
			def encode(value)
				value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d %H:%M:%S.%N") : value
			end
		end

		class TimestampUtc < SimpleEncoder
			def encode(value)
				value.respond_to?(:utc) ? value.utc.strftime("%Y-%m-%d %H:%M:%S.%N") : value
			end
		end

		class TimestampWithTimeZone < SimpleEncoder
			def encode(value)
				value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d %H:%M:%S.%N %:z") : value
			end
		end
	end
end # module PG
