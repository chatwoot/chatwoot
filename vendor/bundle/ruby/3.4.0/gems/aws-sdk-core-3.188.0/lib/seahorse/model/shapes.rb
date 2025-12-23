# frozen_string_literal: true

require 'set'

module Seahorse
  module Model
    module Shapes

      class ShapeRef

        def initialize(options = {})
          @metadata = {}
          @required = false
          @deprecated = false
          @location = nil
          @location_name = nil
          @event = false
          @eventstream = false
          @eventpayload = false
          @eventpayload_type = ''.freeze
          @eventheader = false
          @eventheader_type = ''.freeze
          options.each do |key, value|
            if key == :metadata
              value.each do |k,v|
                self[k] = v
              end
            else
              send("#{key}=", value)
            end
          end
        end

        # @return [Shape]
        attr_accessor :shape

        # @return [Boolean]
        attr_accessor :required

        # @return [String, nil]
        attr_accessor :documentation

        # @return [Boolean]
        attr_accessor :deprecated

        # @return [Boolean]
        attr_accessor :event

        # @return [Boolean]
        attr_accessor :eventstream

        # @return [Boolean]
        attr_accessor :eventpayload

        # @return [Boolean]
        attr_accessor :eventheader

        # @return [String]
        attr_accessor :eventpayload_type

        # @return [Boolean]
        attr_accessor :eventheader_type

        # @return [Boolean]
        attr_accessor :document

        # @return [String, nil]
        def location
          @location || (shape && shape[:location])
        end

        def location= location
          @location = location
        end

        # @return [String, nil]
        def location_name
          @location_name || (shape && shape[:location_name])
        end

        def location_name= location_name
          @location_name = location_name
        end

        # Gets metadata for the given `key`.
        def [](key)
          if @metadata.key?(key.to_s)
            @metadata[key.to_s]
          else
            @shape[key.to_s]
          end
        end

        # Sets metadata for the given `key`.
        def []=(key, value)
          @metadata[key.to_s] = value
        end

      end

      class Shape

        def initialize(options = {})
          @metadata = {}
          options.each_pair do |key, value|
            if respond_to?("#{key}=")
              send("#{key}=", value)
            else
              self[key] = value
            end
          end
        end

        # @return [String]
        attr_accessor :name

        # @return [String, nil]
        attr_accessor :documentation

        # @return [Boolean]
        attr_accessor :union

        # Gets metadata for the given `key`.
        def [](key)
          @metadata[key.to_s]
        end

        # Sets metadata for the given `key`.
        def []=(key, value)
          @metadata[key.to_s] = value
        end

      end

      class BlobShape < Shape

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class BooleanShape < Shape; end

      class FloatShape < Shape

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class IntegerShape < Shape

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class ListShape < Shape

        # @return [ShapeRef]
        attr_accessor :member

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

        # @return [Boolean]
        attr_accessor :flattened

      end

      class MapShape < Shape

        # @return [ShapeRef]
        attr_accessor :key

        # @return [ShapeRef]
        attr_accessor :value

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

        # @return [Boolean]
        attr_accessor :flattened

      end

      class StringShape < Shape

        # @return [Set<String>, nil]
        attr_accessor :enum

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class StructureShape < Shape

        def initialize(options = {})
          @members = {}
          @members_by_location_name = {}
          @required = Set.new
          super
        end

        # @return [Set<Symbol>]
        attr_accessor :required

        # @return [Class<Struct>]
        attr_accessor :struct_class

        # @param [Symbol] name
        # @param [ShapeRef] shape_ref
        def add_member(name, shape_ref)
          name = name.to_sym
          @required << name if shape_ref.required
          @members_by_location_name[shape_ref.location_name] = [name, shape_ref]
          @members[name] = shape_ref
        end

        # @return [Array<Symbol>]
        def member_names
          @members.keys
        end

        # @param [Symbol] member_name
        # @return [Boolean] Returns `true` if there exists a member with
        #   the given name.
        def member?(member_name)
          @members.key?(member_name.to_sym)
        end

        # @return [Enumerator<[Symbol,ShapeRef]>]
        def members
          @members.to_enum
        end

        # @param [Symbol] name
        # @return [ShapeRef]
        def member(name)
          if member?(name)
            @members[name.to_sym]
          else
            raise ArgumentError, "no such member #{name.inspect}"
          end
        end

        # @api private
        def member_by_location_name(location_name)
          @members_by_location_name[location_name]
        end

      end

      class UnionShape < StructureShape
        def initialize(options = {})
          @member_subclasses = {}
          super options.merge(union: true)
        end

        # @api private
        def member_subclass(member)
          @member_subclasses[member]
        end

        # @api private
        def add_member_subclass(member, subclass)
          @member_subclasses[member] = subclass
        end
      end

      class TimestampShape < Shape; end

      class DocumentShape < Shape; end

    end
  end
end
