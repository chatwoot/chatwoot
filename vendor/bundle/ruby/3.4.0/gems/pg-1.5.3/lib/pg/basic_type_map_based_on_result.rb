# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )

# Simple set of rules for type casting common PostgreSQL types from Ruby
# to PostgreSQL.
#
# OIDs of supported type casts are not hard-coded in the sources, but are retrieved from the
# PostgreSQL's +pg_type+ table in PG::BasicTypeMapBasedOnResult.new .
#
# This class works equal to PG::BasicTypeMapForResults, but does not define decoders for
# the given result OIDs, but encoders. So it can be used to type cast field values based on
# the type OID retrieved by a separate SQL query.
#
# PG::TypeMapByOid#build_column_map(result) can be used to generate a result independent
# PG::TypeMapByColumn type map, which can subsequently be used to cast query bind parameters
# or #put_copy_data fields.
#
# Example:
#   conn.exec( "CREATE TEMP TABLE copytable (t TEXT, i INT, ai INT[])" )
#
#   # Retrieve table OIDs per empty result set.
#   res = conn.exec( "SELECT * FROM copytable LIMIT 0" )
#   # Build a type map for common ruby to database type encoders.
#   btm = PG::BasicTypeMapBasedOnResult.new(conn)
#   # Build a PG::TypeMapByColumn with encoders suitable for copytable.
#   tm = btm.build_column_map( res )
#   row_encoder = PG::TextEncoder::CopyRow.new type_map: tm
#
#   conn.copy_data( "COPY copytable FROM STDIN", row_encoder ) do |res|
#     conn.put_copy_data ['a', 123, [5,4,3]]
#   end
# This inserts a single row into copytable with type casts from ruby to
# database types using text format.
#
# Very similar with binary format:
#
#   conn.exec( "CREATE TEMP TABLE copytable (t TEXT, i INT, blob bytea, created_at timestamp)" )
#   # Retrieve table OIDs per empty result set in binary format.
#   res = conn.exec_params( "SELECT * FROM copytable LIMIT 0", [], 1 )
#   # Build a type map for common ruby to database type encoders.
#   btm = PG::BasicTypeMapBasedOnResult.new(conn)
#   # Build a PG::TypeMapByColumn with encoders suitable for copytable.
#   tm = btm.build_column_map( res )
#   row_encoder = PG::BinaryEncoder::CopyRow.new type_map: tm
#
#   conn.copy_data( "COPY copytable FROM STDIN WITH (FORMAT binary)", row_encoder ) do |res|
#     conn.put_copy_data ['a', 123, "\xff\x00".b, Time.now]
#   end
#
# This inserts a single row into copytable with type casts from ruby to
# database types using binary copy and value format.
# Binary COPY is faster than text format but less portable and less readable and pg offers fewer en-/decoders of database types.
#
class PG::BasicTypeMapBasedOnResult < PG::TypeMapByOid
	include PG::BasicTypeRegistry::Checker

	def initialize(connection_or_coder_maps, registry: nil)
		@coder_maps = build_coder_maps(connection_or_coder_maps, registry: registry)

		# Populate TypeMapByOid hash with encoders
		@coder_maps.each_format(:encoder).flat_map{|f| f.coders }.each do |coder|
			add_coder(coder)
		end
	end
end
