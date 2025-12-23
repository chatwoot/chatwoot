# frozen_string_literal: true

# Polyfill for String#byteindex, which didn't exist until Ruby 3.2.
if !("".respond_to?(:byteindex))
  String.include(
    Module.new {
      def byteindex(needle, offset = 0)
        charindex = index(needle, offset)
        slice(0...charindex).bytesize if charindex
      end
    }
  )
end
