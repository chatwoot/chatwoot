json.id portal.id
json.color portal.color
json.custom_domain portal.custom_domain
json.header_text portal.header_text
json.homepage_link portal.homepage_link
json.name portal.name
json.page_title portal.page_title
json.slug portal.slug
json.archived portal.archived

json.config do
  json.allowed_locales do
    json.array! portal.config['allowed_locales'].each do |locale|
      json.partial! 'api/v1/models/portal_config', formats: [:json], locale: locale, portal: portal
    end
  end
end

json.logo portal.file_base_data if portal.logo.present?

json.portal_members do
  if portal.members.any?
    json.array! portal.members.each do |member|
      json.partial! 'api/v1/models/agent', formats: [:json], resource: member
    end
  end
end

json.meta do
  json.all_articles_count portal.articles.size
  json.archived_articles_count portal.articles.archived.size
  json.published_count portal.articles.published.size
  json.draft_articles_count portal.articles.draft.size
  json.mine_articles_count portal.articles.search_by_author(current_user.id).size if current_user.present?
  json.categories_count portal.categories.size
  json.default_locale portal.default_locale
end
