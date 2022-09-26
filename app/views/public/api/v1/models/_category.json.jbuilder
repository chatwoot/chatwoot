json.name category.name
json.slug category.slug
json.locale category.locale
json.description category.description
json.position category.position

json.related_categories do
  if category.related_categories.any?
    json.array! category.related_categories.each do |related_category|
      json.partial! partial: 'public/api/v1/models/associated_category.json.jbuilder', category: related_category
    end
  end
end

if category.parent_category.present?
  json.parent_category do
    json.partial! partial: 'public/api/v1/models/associated_category.json.jbuilder', category: category.parent_category
  end
end

if category.root_category.present?
  json.root_category do
    json.partial! partial: 'public/api/v1/models/associated_category.json.jbuilder', category: category.root_category
  end
end

json.meta do
  json.articles_count category.articles.published.size
end
