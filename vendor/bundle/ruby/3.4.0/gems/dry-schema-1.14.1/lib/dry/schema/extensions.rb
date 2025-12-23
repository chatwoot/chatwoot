# frozen_string_literal: true

Dry::Schema.register_extension(:monads) do
  require "dry/schema/extensions/monads"
end

Dry::Schema.register_extension(:hints) do
  require "dry/schema/extensions/hints"
end

Dry::Schema.register_extension(:struct) do
  require "dry/schema/extensions/struct"
end

Dry::Schema.register_extension(:info) do
  require "dry/schema/extensions/info"
end

Dry::Schema.register_extension(:json_schema) do
  require "dry/schema/extensions/json_schema"
end
