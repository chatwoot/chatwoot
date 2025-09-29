# frozen_string_literal: true

json.payload do
  json.partial! 'company', company: @company
end
