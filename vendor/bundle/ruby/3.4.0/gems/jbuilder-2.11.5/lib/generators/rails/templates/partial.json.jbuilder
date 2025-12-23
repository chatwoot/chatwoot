json.extract! <%= singular_table_name %>, <%= full_attributes_list %>
json.url <%= singular_table_name %>_url(<%= singular_table_name %>, format: :json)
<%- virtual_attributes.each do |attribute| -%>
<%- if attribute.type == :rich_text -%>
json.<%= attribute.name %> <%= singular_table_name %>.<%= attribute.name %>.to_s
<%- elsif attribute.type == :attachment -%>
json.<%= attribute.name %> url_for(<%= singular_table_name %>.<%= attribute.name %>)
<%- elsif attribute.type == :attachments -%>
json.<%= attribute.name %> do
  json.array!(<%= singular_table_name %>.<%= attribute.name %>) do |<%= attribute.singular_name %>|
    json.id <%= attribute.singular_name %>.id
    json.url url_for(<%= attribute.singular_name %>)
  end
end
<%- end -%>
<%- end -%>
