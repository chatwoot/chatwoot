json.payload do
  json.array! @macros do |macro|
    json.partial! 'api/v1/models/macro.json.jbuilder', macro: macro
  end
end
