json.id category.id
json.name category.name
json.slug category.slug
json.locale category.locale
json.description category.description
json.position category.position
json.account_id category.account_id
json.icon category.icon

json.related_categories do
  if category.related_categories.any?
    json.array! category.related_categories.each do |related_category|
      json.partial! 'api/v1/accounts/categories/associated_category', formats: [:json], category: related_category
    end
  end
end

if category.parent_category.present?
  json.parent_category do
    json.partial! 'api/v1/accounts/categories/associated_category', formats: [:json], category: category.parent_category
  end
end

if category.root_category.present?
  json.root_category do
    json.partial! 'api/v1/accounts/categories/associated_category', formats: [:json], category: category.root_category
  end
end

json.meta do
  json.articles_count category.articles.search(locale: @current_locale).size
end
