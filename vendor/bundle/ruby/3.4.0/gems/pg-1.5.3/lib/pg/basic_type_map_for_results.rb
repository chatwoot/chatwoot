# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )

# Simple set of rules for type casting common PostgreSQL types to Ruby.
#
# OIDs of supported type casts are not hard-coded in the sources, but are retrieved from the
# PostgreSQL's +pg_type+ table in PG::BasicTypeMapForResults.new .
#
# Result values are type casted based on the type OID of the given result column.
#
# Higher level libraries will most likely not make use of this class, but use their
# own set of rules to choose suitable encoders and decoders.
#
# Example:
#   conn = PG::Connection.new
#   # Assign a default ruleset for type casts of output values.
#   conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn)
#   # Execute a query.
#   res = conn.exec_params( "SELECT $1::INT", ['5'] )
#   # Retrieve and cast the result value. Value format is 0 (text) and OID is 20. Therefore typecasting
#   # is done by PG::TextDecoder::Integer internally for all value retrieval methods.
#   res.values  # => [[5]]
#
# PG::TypeMapByOid#build_column_map(result) can be used to generate
# a result independent PG::TypeMapByColumn type map, which can subsequently be used
# to cast #get_copy_data fields:
#
# For the following table:
#   conn.exec( "CREATE TABLE copytable AS VALUES('a', 123, '{5,4,3}'::INT[])" )
#
#   # Retrieve table OIDs per empty result set.
#   res = conn.exec( "SELECT * FROM copytable LIMIT 0" )
#   # Build a type map for common database to ruby type decoders.
#   btm = PG::BasicTypeMapForResults.new(conn)
#   # Build a PG::TypeMapByColumn with decoders suitable for copytable.
#   tm = btm.build_column_map( res )
#   row_decoder = PG::TextDecoder::CopyRow.new type_map: tm
#
#   conn.copy_data( "COPY copytable TO STDOUT", row_decoder ) do |res|
#     while row=conn.get_copy_data
#       p row
#     end
#   end
# This prints the rows with type casted columns:
#   ["a", 123, [5, 4, 3]]
#
# Very similar with binary format:
#
#   conn.exec( "CREATE TABLE copytable AS VALUES('a', 123, '2023-03-19 18:39:44'::TIMESTAMP)" )
#
#   # Retrieve table OIDs per empty result set in binary format.
#   res = conn.exec_params( "SELECT * FROM copytable LIMIT 0", [], 1 )
#   # Build a type map for common database to ruby type decoders.
#   btm = PG::BasicTypeMapForResults.new(conn)
#   # Build a PG::TypeMapByColumn with decoders suitable for copytable.
#   tm = btm.build_column_map( res )
#   row_decoder = PG::BinaryDecoder::CopyRow.new type_map: tm
#
#   conn.copy_data( "COPY copytable TO STDOUT WITH (FORMAT binary)", row_decoder ) do |res|
#     while row=conn.get_copy_data
#       p row
#     end
#   end
# This prints the rows with type casted columns:
#   ["a", 123, 2023-03-19 18:39:44 UTC]
#
# See also PG::BasicTypeMapBasedOnResult for the encoder direction and PG::BasicTypeRegistry for the definition of additional types.
class PG::BasicTypeMapForResults < PG::TypeMapByOid
	include PG::BasicTypeRegistry::Checker

	class WarningTypeMap < PG::TypeMapInRuby
		def initialize(typenames)
			@already_warned = {}
			@typenames_by_oid = typenames
		end

		def typecast_result_value(result, _tuple, field)
			format = result.fformat(field)
			oid = result.ftype(field)
			unless @already_warned.dig(format, oid)
				warn "Warning: no type cast defined for type #{@typenames_by_oid[oid].inspect} format #{format} with oid #{oid}. Please cast this type explicitly to TEXT to be safe for future changes."
				unless frozen?
					@already_warned[format] ||= {}
					@already_warned[format][oid] = true
				end
			end
			super
		end
	end

	def initialize(connection_or_coder_maps, registry: nil)
		@coder_maps = build_coder_maps(connection_or_coder_maps, registry: registry)

		# Populate TypeMapByOid hash with decoders
		@coder_maps.each_format(:decoder).flat_map{|f| f.coders }.each do |coder|
			add_coder(coder)
		end

		typenames = @coder_maps.typenames_by_oid
		self.default_type_map = WarningTypeMap.new(typenames)
	end
end
