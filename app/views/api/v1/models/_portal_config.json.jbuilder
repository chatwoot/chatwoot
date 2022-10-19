json.code locale
json.articles_count portal.articles.search({ locale: locale }).size
json.categories_count portal.categories.search_by_locale(locale).size
