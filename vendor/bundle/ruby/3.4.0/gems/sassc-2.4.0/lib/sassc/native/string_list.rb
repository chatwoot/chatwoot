# frozen_string_literal: true

module SassC
  module Native
    class StringList < FFI::Struct
      layout :string_list, StringList.ptr,
             :string, :string
    end
  end
end
