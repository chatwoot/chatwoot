json.id category.id
json.name category.name
json.slug category.slug
json.locale category.locale
json.description category.description
json.position category.position
json.account_id category.account_id

if category.linked_categories.any?
  json.array! category.linked_categories.each do |linked_category|
    json.partial! 'api/v1/accounts/categories/associated_category.json.jbuilder', category: linked_category
  end
end

json.partial! 'api/v1/accounts/categories/associated_category.json.jbuilder', category: category.parent_category if category.parent_category.present?
