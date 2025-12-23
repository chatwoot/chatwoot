# frozen_string_literal: true

module SassC
  module Native
    class SassValue < FFI::Union; end

    SassTag = enum(
      :sass_boolean,
      :sass_number,
      :sass_color,
      :sass_string,
      :sass_list,
      :sass_map,
      :sass_null,
      :sass_error,
      :sass_warning
    )

    SassSeparator = enum(
      :sass_comma,
      :sass_space
    )

    class SassUnknown < FFI::Struct
      layout :tag, SassTag
    end

    class SassBoolean < FFI::Struct
      layout :tag, SassTag,
             :value, :bool
    end

    class SassNumber < FFI::Struct
      layout :tag, SassTag,
             :value, :double,
             :unit, :string
    end

    class SassColor < FFI::Struct
      layout :tag, SassTag,
             :r, :double,
             :g, :double,
             :b, :double,
             :a, :double
    end

    class SassString < FFI::Struct
      layout :tag, SassTag,
             :value, :string
    end

    class SassList < FFI::Struct
      layout :tag, SassTag,
             :separator, SassSeparator,
             :length, :size_t,
             :values, :pointer
    end

    class SassMapPair < FFI::Struct
      layout :key, SassValue.ptr,
             :value, SassValue.ptr
    end

    class SassMap < FFI::Struct
      layout :tag, SassTag,
             :length, :size_t,
             :pairs, SassMapPair.ptr
    end

    class SassNull < FFI::Struct
      layout :tag, SassTag
    end

    class SassError < FFI::Struct
      layout :tag, SassTag,
             :message, :string
    end

    class SassWarning < FFI::Struct
      layout :tag, SassTag,
             :message, :string
    end

    class SassValue # < FFI::Union
      layout :unknown, SassUnknown,
             :boolean, SassBoolean,
             :number, SassNumber,
             :color, SassColor,
             :string, SassString,
             :list, SassList,
             :map, SassMap,
             :null, SassNull,
             :error, SassError,
             :warning, SassWarning
    end
  end
end
