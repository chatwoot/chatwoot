json.id article.id
json.category_id article.category_id
json.title article.title
json.content article.content
json.description article.description
json.status article.status
json.position article.position
json.account_id article.account_id
json.last_updated_at article.updated_at
json.slug article.slug

if article.portal.present?
  json.portal do
    json.custom_domain article.portal.custom_domain
    json.header_text article.portal.header_text
    json.homepage_link article.portal.homepage_link
    json.name article.portal.name
    json.page_title article.portal.page_title
    json.slug article.portal.slug
    json.logo article.portal.file_base_data if article.portal.logo.present?
  end
end

if article.category.present?
  json.category do
    json.id article.category.id
    json.slug article.category.slug
    json.locale article.category.locale
  end
end

json.views article.views

if article.author.present?
  json.author do
    json.partial! 'public/api/v1/models/hc/author', formats: [:json], resource: article.author
  end
end

json.link "hc/#{article.portal.slug}/articles/#{article.slug}"
