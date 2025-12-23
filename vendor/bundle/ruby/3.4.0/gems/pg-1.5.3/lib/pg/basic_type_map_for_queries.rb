# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )

# Simple set of rules for type casting common Ruby types to PostgreSQL.
#
# OIDs of supported type casts are not hard-coded in the sources, but are retrieved from the
# PostgreSQL's pg_type table in PG::BasicTypeMapForQueries.new .
#
# Query params are type casted based on the class of the given value.
#
# Higher level libraries will most likely not make use of this class, but use their
# own derivation of PG::TypeMapByClass or another set of rules to choose suitable
# encoders and decoders for the values to be sent.
#
# Example:
#   conn = PG::Connection.new
#   # Assign a default ruleset for type casts of input and output values.
#   conn.type_map_for_queries = PG::BasicTypeMapForQueries.new(conn)
#   # Execute a query. The Integer param value is typecasted internally by PG::BinaryEncoder::Int8.
#   # The format of the parameter is set to 0 (text) and the OID of this parameter is set to 20 (int8).
#   res = conn.exec_params( "SELECT $1", [5] )
class PG::BasicTypeMapForQueries < PG::TypeMapByClass
	# Helper class for submission of binary strings into bytea columns.
	#
	# Since PG::BasicTypeMapForQueries chooses the encoder to be used by the class of the submitted value,
	# it's necessary to send binary strings as BinaryData.
	# That way they're distinct from text strings.
	# Please note however that PG::BasicTypeMapForResults delivers bytea columns as plain String
	# with binary encoding.
	#
	#   conn.type_map_for_queries = PG::BasicTypeMapForQueries.new(conn)
	#   conn.exec("CREATE TEMP TABLE test (data bytea)")
	#   bd = PG::BasicTypeMapForQueries::BinaryData.new("ab\xff\0cd")
	#   conn.exec_params("INSERT INTO test (data) VALUES ($1)", [bd])
	class BinaryData < String
	end

	class UndefinedEncoder < RuntimeError
	end

	include PG::BasicTypeRegistry::Checker

	# Create a new type map for query submission
	#
	# Options:
	# * +registry+: Custom type registry, nil for default global registry
	# * +if_undefined+: Optional +Proc+ object which is called, if no type for an parameter class is not defined in the registry.
	#   The +Proc+ object is called with the name and format of the missing type.
	#   Its return value is not used.
	def initialize(connection_or_coder_maps, registry: nil, if_undefined: nil)
		@coder_maps = build_coder_maps(connection_or_coder_maps, registry: registry)
		@array_encoders_by_klass = array_encoders_by_klass
		@encode_array_as = :array
		@if_undefined = if_undefined || method(:raise_undefined_type).to_proc
		init_encoders
	end

	private def raise_undefined_type(oid_name, format)
		raise UndefinedEncoder, "no encoder defined for type #{oid_name.inspect} format #{format}"
	end

	# Change the mechanism that is used to encode ruby array values
	#
	# Possible values:
	# * +:array+ : Encode the ruby array as a PostgreSQL array.
	#   The array element type is inferred from the class of the first array element. This is the default.
	# * +:json+ : Encode the ruby array as a JSON document.
	# * +:record+ : Encode the ruby array as a composite type row.
	# * <code>"_type"</code> : Encode the ruby array as a particular PostgreSQL type.
	#   All PostgreSQL array types are supported.
	#   If there's an encoder registered for the elements +type+, it will be used.
	#   Otherwise a string conversion (by +value.to_s+) is done.
	def encode_array_as=(pg_type)
		case pg_type
			when :array
			when :json
			when :record
			when /\A_/
			else
				raise ArgumentError, "invalid pg_type #{pg_type.inspect}"
		end

		@encode_array_as = pg_type

		init_encoders
	end

	attr_reader :encode_array_as

	private

	def init_encoders
		coders.each { |kl, c| self[kl] = nil } # Clear type map
		populate_encoder_list
		@textarray_encoder = coder_by_name(0, :encoder, '_text')
	end

	def coder_by_name(format, direction, name)
		check_format_and_direction(format, direction)
		@coder_maps.map_for(format, direction).coder_by_name(name)
	end

	def undefined(name, format)
		@if_undefined.call(name, format)
	end

	def populate_encoder_list
		DEFAULT_TYPE_MAP.each do |klass, selector|
			if Array === selector
				format, name, oid_name = selector
				coder = coder_by_name(format, :encoder, name).dup
				if coder
					if oid_name
						oid_coder = coder_by_name(format, :encoder, oid_name)
						if oid_coder
							coder.oid = oid_coder.oid
						else
							undefined(oid_name, format)
						end
					else
						coder.oid = 0
					end
					self[klass] = coder
				else
					undefined(name, format)
				end
			else

				case @encode_array_as
					when :array
						self[klass] = selector
					when :json
						self[klass] = PG::TextEncoder::JSON.new
					when :record
						self[klass] = PG::TextEncoder::Record.new type_map: self
					when /\A_/
						coder = coder_by_name(0, :encoder, @encode_array_as)
						if coder
							self[klass] = coder
						else
							undefined(@encode_array_as, format)
						end
					else
						raise ArgumentError, "invalid pg_type #{@encode_array_as.inspect}"
				end
			end
		end
	end

	def array_encoders_by_klass
		DEFAULT_ARRAY_TYPE_MAP.inject({}) do |h, (klass, (format, name))|
			h[klass] = coder_by_name(format, :encoder, name)
			h
		end
	end

	def get_array_type(value)
		elem = value
		while elem.kind_of?(Array)
			elem = elem.first
		end
		@array_encoders_by_klass[elem.class] ||
				elem.class.ancestors.lazy.map{|ancestor| @array_encoders_by_klass[ancestor] }.find{|a| a } ||
				@textarray_encoder
	end

	DEFAULT_TYPE_MAP = PG.make_shareable({
		TrueClass => [1, 'bool', 'bool'],
		FalseClass => [1, 'bool', 'bool'],
		# We use text format and no type OID for numbers, because setting the OID can lead
		# to unnecessary type conversions on server side.
		Integer => [0, 'int8'],
		Float => [0, 'float8'],
		BigDecimal => [0, 'numeric'],
		Time => [0, 'timestamptz'],
		# We use text format and no type OID for IPAddr, because setting the OID can lead
		# to unnecessary inet/cidr conversions on the server side.
		IPAddr => [0, 'inet'],
		Hash => [0, 'json'],
		Array => :get_array_type,
		BinaryData => [1, 'bytea'],
	})
	private_constant :DEFAULT_TYPE_MAP

	DEFAULT_ARRAY_TYPE_MAP = PG.make_shareable({
		TrueClass => [0, '_bool'],
		FalseClass => [0, '_bool'],
		Integer => [0, '_int8'],
		String => [0, '_text'],
		Float => [0, '_float8'],
		BigDecimal => [0, '_numeric'],
		Time => [0, '_timestamptz'],
		IPAddr => [0, '_inet'],
	})
	private_constant :DEFAULT_ARRAY_TYPE_MAP
end
