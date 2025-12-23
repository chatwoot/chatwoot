# frozen_string_literal: true

# The dispatcher verifies a correctness of the source name
# of param or option, taken as a `:source` option.
#
# We allow any stringified name for the source.
# For example, this syntax is correct because we accept any key
# in the original hash of arguments, but give them proper names:
#
# ```ruby
# class Foo
#   extend Dry::Initializer
#
#   option "", as: :first
#   option 1,  as: :second
# end
#
# foo = Foo.new("": 42, 1: 666)
# foo.first  # => 42
# foo.second # => 666
# ```
#
module Dry
  module Initializer
    module Dispatchers
      module PrepareSource
        module_function

        def call(source:, **options)
          {source: source.to_s.to_sym, **options}
        end
      end
    end
  end
end
