# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )


class PG::Result

	# Apply a type map for all value retrieving methods.
	#
	# +type_map+: a PG::TypeMap instance.
	#
	# This method is equal to #type_map= , but returns self, so that calls can be chained.
	#
	# See also PG::BasicTypeMapForResults
	def map_types!(type_map)
		self.type_map = type_map
		return self
	end

	# Set the data type for all field name returning methods.
	#
	# +type+: a Symbol defining the field name type.
	#
	# This method is equal to #field_name_type= , but returns self, so that calls can be chained.
	def field_names_as(type)
		self.field_name_type = type
		return self
	end

	### Return a String representation of the object suitable for debugging.
	def inspect
		str = self.to_s
		str[-1,0] = if cleared?
			" cleared"
		else
			" status=#{res_status(result_status)} ntuples=#{ntuples} nfields=#{nfields} cmd_tuples=#{cmd_tuples}"
		end
		return str
	end

end # class PG::Result

