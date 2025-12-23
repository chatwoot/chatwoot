# -*- ruby -*-
# frozen_string_literal: true

module PG

	class Coder

		module BinaryFormatting
			def initialize(hash={}, **kwargs)
				warn("PG::Coder.new(hash) is deprecated. Please use keyword arguments instead! Called from #{caller.first}", category: :deprecated) unless hash.empty?
				super(format: 1, **hash, **kwargs)
			end
		end


		# Create a new coder object based on the attribute Hash.
		def initialize(hash=nil, **kwargs)
			warn("PG::Coder.new(hash) is deprecated. Please use keyword arguments instead! Called from #{caller.first}", category: :deprecated) if hash

			(hash || kwargs).each do |key, val|
				send("#{key}=", val)
			end
		end

		def dup
			self.class.new(**to_h)
		end

		# Returns coder attributes as Hash.
		def to_h
			{
				oid: oid,
				format: format,
				flags: flags,
				name: name,
			}
		end

		def ==(v)
			self.class == v.class && to_h == v.to_h
		end

		def marshal_dump
			Marshal.dump(to_h)
		end

		def marshal_load(str)
			initialize(**Marshal.load(str))
		end

		def inspect
			str = self.to_s
			oid_str = " oid=#{oid}" unless oid==0
			format_str = " format=#{format}" unless format==0
			name_str = " #{name.inspect}" if name
			str[-1,0] = "#{name_str} #{oid_str}#{format_str}"
			str
		end

		def inspect_short
			str = case format
				when 0 then "T"
				when 1 then "B"
				else format.to_s
			end
			str += "E" if respond_to?(:encode)
			str += "D" if respond_to?(:decode)

			"#{name || self.class.name}:#{str}"
		end
	end

	class CompositeCoder < Coder
		def to_h
			{ **super,
				elements_type: elements_type,
				needs_quotation: needs_quotation?,
				delimiter: delimiter,
			}
		end

		def inspect
			str = super
			str[-1,0] = " elements_type=#{elements_type.inspect} #{needs_quotation? ? 'needs' : 'no'} quotation"
			str
		end
	end

	class CopyCoder < Coder
		def to_h
			{ **super,
				type_map: type_map,
				delimiter: delimiter,
				null_string: null_string,
			}
		end
	end

	class RecordCoder < Coder
		def to_h
			{ **super,
				type_map: type_map,
			}
		end
	end
end # module PG
