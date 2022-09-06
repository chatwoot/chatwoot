json.payload do
  json.partial! 'api/v1/models/macro.json.jbuilder', macro: @macro
end
