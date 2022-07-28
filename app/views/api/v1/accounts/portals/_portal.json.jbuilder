json.id portal.id
json.color portal.color
json.custom_domain portal.custom_domain
json.header_text portal.header_text
json.homepage_link portal.homepage_link
json.name portal.name
json.page_title portal.page_title
json.slug portal.slug
json.archived portal.archived
json.config portal.config
json.logo portal.file_base_data if portal.logo.present?

json.portal_members do
  if portal.members.any?
    json.array! portal.members.each do |member|
      json.partial! 'api/v1/models/agent.json.jbuilder', resource: member
    end
  end
end

json.meta do
  json.articles_count portal.articles.size
  json.categories_count portal.categories.size
  json.default_locale portal.default_locale
end
