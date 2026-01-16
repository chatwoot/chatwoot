json.id @location.id
json.name @location.name
json.description @location.description
json.type_name @location.type_name
json.parent_location_id @location.parent_location_id

if @location.parent_location.present?
  json.parent_location do
    json.id @location.parent_location.id
    json.name @location.parent_location.name
  end
else
  json.parent_location nil
end

if @location.address.present?
  json.address do
    json.id @location.address.id
    json.street @location.address.street
    json.exterior_number @location.address.exterior_number
    json.interior_number @location.address.interior_number
    json.neighborhood @location.address.neighborhood
    json.postal_code @location.address.postal_code
    json.city @location.address.city
    json.state @location.address.state
    json.email @location.address.email
    json.phone @location.address.phone
    json.webpage @location.address.webpage
    json.establishment_summary @location.address.establishment_summary
  end
else
  json.address nil
end

json.has_children @location.children?
json.depth @location.depth
json.full_path @location.full_path
json.created_at @location.created_at
json.updated_at @location.updated_at

# Include ancestors for full hierarchy display
json.ancestors @location.ancestors do |ancestor|
  json.id ancestor.id
  json.name ancestor.name
end

# Include direct children
json.child_locations @location.child_locations do |child|
  json.id child.id
  json.name child.name
  json.has_children child.children?
end
