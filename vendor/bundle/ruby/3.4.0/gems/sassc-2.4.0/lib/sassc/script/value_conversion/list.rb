# frozen_string_literal: true

module SassC
  module Script
    module ValueConversion
      SEPARATORS = {
        space: :sass_space,
        comma: :sass_comma
      }

      class List < Base
        def to_native
          list = @value.to_a
          sep = SEPARATORS.fetch(@value.separator)
          native_list = Native::make_list(list.size, sep)
          list.each_with_index do |item, index|
            native_item = ValueConversion.to_native(item)
            Native::list_set_value(native_list, index, native_item)
          end
          native_list
        end
      end
    end
  end
end
