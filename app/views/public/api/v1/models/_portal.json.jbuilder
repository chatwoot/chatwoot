json.custom_domain portal.custom_domain
json.header_text portal.header_text
json.homepage_link portal.homepage_link
json.name portal.name
json.page_title portal.page_title
json.slug portal.slug

json.categories do
  if portal.categories.any?
    json.array! portal.categories.each do |category|
      json.partial! 'public/api/v1/models/category.json.jbuilder', category: category
    end
  end
end

json.meta do
  json.articles_count portal.articles.published.size
  json.categories_count portal.categories.size
  json.default_locale portal.default_locale
end
