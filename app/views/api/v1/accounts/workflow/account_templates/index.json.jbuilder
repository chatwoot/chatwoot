json.payload do
  json.array! @account_templates do |account_template|
    json.partial! 'api/v1/models/workflow/account_template.json.jbuilder', resource: account_template
  end
end
