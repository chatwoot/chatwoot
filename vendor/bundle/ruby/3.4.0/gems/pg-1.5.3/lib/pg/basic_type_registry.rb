# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )

# This class defines the mapping between PostgreSQL types and encoder/decoder classes for PG::BasicTypeMapForResults, PG::BasicTypeMapForQueries and PG::BasicTypeMapBasedOnResult.
#
# Additional types can be added like so:
#
#   require 'pg'
#   require 'ipaddr'
#
#   class InetDecoder < PG::SimpleDecoder
#     def decode(string, tuple=nil, field=nil)
#       IPAddr.new(string)
#     end
#   end
#   class InetEncoder < PG::SimpleEncoder
#     def encode(ip_addr)
#       ip_addr.to_s
#     end
#   end
#
#   conn = PG.connect
#   regi = PG::BasicTypeRegistry.new.register_default_types
#   regi.register_type(0, 'inet', InetEncoder, InetDecoder)
#   conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: regi)
class PG::BasicTypeRegistry
	# An instance of this class stores the coders that should be used for a particular wire format (text or binary)
	# and type cast direction (encoder or decoder).
	#
	# Each coder object is filled with the PostgreSQL type name, OID, wire format and array coders are filled with the base elements_type.
	class CoderMap
		# Hash of text types that don't require quotation, when used within composite types.
		#   type.name => true
		DONT_QUOTE_TYPES = %w[
			int2 int4 int8
			float4 float8
			oid
			bool
			date timestamp timestamptz
		].inject({}){|h,e| h[e] = true; h }.freeze
		private_constant :DONT_QUOTE_TYPES

		def initialize(result, coders_by_name, format, arraycoder)
			coder_map = {}

			arrays, nodes = result.partition { |row| row['typinput'] == 'array_in' }

			# populate the base types
			nodes.find_all { |row| coders_by_name.key?(row['typname']) }.each do |row|
				coder = coders_by_name[row['typname']].dup
				coder.oid = row['oid'].to_i
				coder.name = row['typname']
				coder.format = format
				coder_map[coder.oid] = coder.freeze
			end

			if arraycoder
				# populate array types
				arrays.each do |row|
					elements_coder = coder_map[row['typelem'].to_i]
					next unless elements_coder

					coder = arraycoder.new
					coder.oid = row['oid'].to_i
					coder.name = row['typname']
					coder.format = format
					coder.elements_type = elements_coder
					coder.needs_quotation = !DONT_QUOTE_TYPES[elements_coder.name]
					coder_map[coder.oid] = coder.freeze
				end
			end

			@coders = coder_map.values.freeze
			@coders_by_name = @coders.inject({}){|h, t| h[t.name] = t; h }.freeze
			@coders_by_oid = @coders.inject({}){|h, t| h[t.oid] = t; h }.freeze
			freeze
		end

		attr_reader :coders
		attr_reader :coders_by_oid
		attr_reader :coders_by_name

		def coder_by_name(name)
			@coders_by_name[name]
		end

		def coder_by_oid(oid)
			@coders_by_oid[oid]
		end
	end

	# An instance of this class stores CoderMap instances to be used for text and binary wire formats
	# as well as encoder and decoder directions.
	#
	# A PG::BasicTypeRegistry::CoderMapsBundle instance retrieves all type definitions from the PostgreSQL server and matches them with the coder definitions of the global PG::BasicTypeRegistry .
	# It provides 4 separate CoderMap instances for the combinations of the two formats and directions.
	#
	# A PG::BasicTypeRegistry::CoderMapsBundle instance can be used to initialize an instance of
	# * PG::BasicTypeMapForResults
	# * PG::BasicTypeMapForQueries
	# * PG::BasicTypeMapBasedOnResult
	# by passing it instead of the connection object like so:
	#
	#   conn = PG::Connection.new
	#   maps = PG::BasicTypeRegistry::CoderMapsBundle.new(conn)
	#   conn.type_map_for_results = PG::BasicTypeMapForResults.new(maps)
	#
	class CoderMapsBundle
		attr_reader :typenames_by_oid

		def initialize(connection, registry: nil)
			registry ||= DEFAULT_TYPE_REGISTRY

			result = connection.exec(<<-SQL).to_a
				SELECT t.oid, t.typname, t.typelem, t.typdelim, ti.proname AS typinput
				FROM pg_type as t
				JOIN pg_proc as ti ON ti.oid = t.typinput
			SQL

			init_maps(registry, result.freeze)
			freeze
		end

		private def init_maps(registry, result)
			@maps = [
				[0, :encoder, PG::TextEncoder::Array],
				[0, :decoder, PG::TextDecoder::Array],
				[1, :encoder, nil],
				[1, :decoder, nil],
			].inject([]) do |h, (format, direction, arraycoder)|
				coders = registry.coders_for(format, direction) || {}
				h[format] ||= {}
				h[format][direction] = CoderMap.new(result, coders, format, arraycoder)
				h
			end.each{|h| h.freeze }.freeze

			@typenames_by_oid = result.inject({}){|h, t| h[t['oid'].to_i] = t['typname']; h }.freeze
		end

		def each_format(direction)
			@maps.map { |f| f[direction] }
		end

		def map_for(format, direction)
			@maps[format][direction]
		end
	end

	module Checker
		ValidFormats = { 0 => true, 1 => true }.freeze
		ValidDirections = { :encoder => true, :decoder => true }.freeze
		private_constant :ValidFormats, :ValidDirections

		protected def check_format_and_direction(format, direction)
			raise(ArgumentError, "Invalid format value %p" % format) unless ValidFormats[format]
			raise(ArgumentError, "Invalid direction %p" % direction) unless ValidDirections[direction]
		end

		protected def build_coder_maps(conn_or_maps, registry: nil)
			if conn_or_maps.is_a?(PG::BasicTypeRegistry::CoderMapsBundle)
				raise ArgumentError, "registry argument must be given to CoderMapsBundle" if registry
				conn_or_maps
			else
				PG::BasicTypeRegistry::CoderMapsBundle.new(conn_or_maps, registry: registry).freeze
			end
		end
	end

	include Checker

	def initialize
		# The key of these hashs maps to the `typname` column from the table pg_type.
		@coders_by_name = []
	end

	# Retrieve a Hash of all en- or decoders for a given wire format.
	# The hash key is the name as defined in table +pg_type+.
	# The hash value is the registered coder object.
	def coders_for(format, direction)
		check_format_and_direction(format, direction)
		@coders_by_name[format]&.[](direction)
	end

	# Register an encoder or decoder instance for casting a PostgreSQL type.
	#
	# Coder#name must correspond to the +typname+ column in the +pg_type+ table.
	# Coder#format can be 0 for text format and 1 for binary.
	def register_coder(coder)
		h = @coders_by_name[coder.format] ||= { encoder: {}, decoder: {} }
		name = coder.name || raise(ArgumentError, "name of #{coder.inspect} must be defined")
		h[:encoder][name] = coder if coder.respond_to?(:encode)
		h[:decoder][name] = coder if coder.respond_to?(:decode)
		self
	end

	# Register the given +encoder_class+ and/or +decoder_class+ for casting a PostgreSQL type.
	#
	# +name+ must correspond to the +typname+ column in the +pg_type+ table.
	# +format+ can be 0 for text format and 1 for binary.
	def register_type(format, name, encoder_class, decoder_class)
		register_coder(encoder_class.new(name: name, format: format).freeze) if encoder_class
		register_coder(decoder_class.new(name: name, format: format).freeze) if decoder_class
		self
	end

	# Alias the +old+ type to the +new+ type.
	def alias_type(format, new, old)
		[:encoder, :decoder].each do |ende|
			enc = @coders_by_name[format][ende][old]
			if enc
				@coders_by_name[format][ende][new] = enc
			else
				@coders_by_name[format][ende].delete(new)
			end
		end
		self
	end

	# Populate the registry with all builtin types of ruby-pg
	def register_default_types
		register_type 0, 'int2', PG::TextEncoder::Integer, PG::TextDecoder::Integer
		alias_type    0, 'int4', 'int2'
		alias_type    0, 'int8', 'int2'
		alias_type    0, 'oid',  'int2'

		register_type 0, 'numeric', PG::TextEncoder::Numeric, PG::TextDecoder::Numeric
		register_type 0, 'text', PG::TextEncoder::String, PG::TextDecoder::String
		alias_type 0, 'varchar', 'text'
		alias_type 0, 'char', 'text'
		alias_type 0, 'bpchar', 'text'
		alias_type 0, 'xml', 'text'
		alias_type 0, 'name', 'text'

		# FIXME: why are we keeping these types as strings?
		# alias_type 'tsvector', 'text'
		# alias_type 'interval', 'text'
		# alias_type 'macaddr',  'text'
		# alias_type 'uuid',     'text'
		#
		# register_type 'money', OID::Money.new
		register_type 0, 'bytea', PG::TextEncoder::Bytea, PG::TextDecoder::Bytea
		register_type 0, 'bool', PG::TextEncoder::Boolean, PG::TextDecoder::Boolean
		# register_type 'bit', OID::Bit.new
		# register_type 'varbit', OID::Bit.new

		register_type 0, 'float4', PG::TextEncoder::Float, PG::TextDecoder::Float
		alias_type 0, 'float8', 'float4'

		# For compatibility reason the timestamp in text format is encoded as local time (TimestampWithoutTimeZone) instead of UTC
		register_type 0, 'timestamp', PG::TextEncoder::TimestampWithoutTimeZone, PG::TextDecoder::TimestampWithoutTimeZone
		register_type 0, 'timestamptz', PG::TextEncoder::TimestampWithTimeZone, PG::TextDecoder::TimestampWithTimeZone
		register_type 0, 'date', PG::TextEncoder::Date, PG::TextDecoder::Date
		# register_type 'time', OID::Time.new
		#
		# register_type 'path', OID::Text.new
		# register_type 'point', OID::Point.new
		# register_type 'polygon', OID::Text.new
		# register_type 'circle', OID::Text.new
		# register_type 'hstore', OID::Hstore.new
		register_type 0, 'json', PG::TextEncoder::JSON, PG::TextDecoder::JSON
		alias_type    0, 'jsonb',  'json'
		# register_type 'citext', OID::Text.new
		# register_type 'ltree', OID::Text.new
		#
		register_type 0, 'inet', PG::TextEncoder::Inet, PG::TextDecoder::Inet
		alias_type 0, 'cidr', 'inet'



		register_type 1, 'int2', PG::BinaryEncoder::Int2, PG::BinaryDecoder::Integer
		register_type 1, 'int4', PG::BinaryEncoder::Int4, PG::BinaryDecoder::Integer
		register_type 1, 'int8', PG::BinaryEncoder::Int8, PG::BinaryDecoder::Integer
		alias_type    1, 'oid',  'int2'

		register_type 1, 'text', PG::BinaryEncoder::String, PG::BinaryDecoder::String
		alias_type 1, 'varchar', 'text'
		alias_type 1, 'char', 'text'
		alias_type 1, 'bpchar', 'text'
		alias_type 1, 'xml', 'text'
		alias_type 1, 'name', 'text'

		register_type 1, 'bytea', PG::BinaryEncoder::Bytea, PG::BinaryDecoder::Bytea
		register_type 1, 'bool', PG::BinaryEncoder::Boolean, PG::BinaryDecoder::Boolean
		register_type 1, 'float4', PG::BinaryEncoder::Float4, PG::BinaryDecoder::Float
		register_type 1, 'float8', PG::BinaryEncoder::Float8, PG::BinaryDecoder::Float
		register_type 1, 'timestamp', PG::BinaryEncoder::TimestampUtc, PG::BinaryDecoder::TimestampUtc
		register_type 1, 'timestamptz', PG::BinaryEncoder::TimestampUtc, PG::BinaryDecoder::TimestampUtcToLocal
		register_type 1, 'date', PG::BinaryEncoder::Date, PG::BinaryDecoder::Date

		self
	end

	alias define_default_types register_default_types

	DEFAULT_TYPE_REGISTRY = PG.make_shareable(PG::BasicTypeRegistry.new.register_default_types)
	private_constant :DEFAULT_TYPE_REGISTRY
end
