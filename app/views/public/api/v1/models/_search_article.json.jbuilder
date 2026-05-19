content = ChatwootMarkdownRenderer.new(article.content.to_s).render_markdown_to_plain_text.squish
snippet = excerpt(content, search_query, radius: 110, omission: '...') ||
          truncate(content, length: 220, separator: ' ')

json.extract! article, :id, :category_id, :title
json.content snippet
json.link generate_article_link(portal_slug, article.slug, nil, false)
