# frozen_string_literal: true

Dry::Types.register_extension(:maybe) do
  require "dry/types/extensions/maybe"
end

Dry::Types.register_extension(:monads) do
  require "dry/types/extensions/monads"
end
