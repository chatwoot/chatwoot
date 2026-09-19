class Captain::Llm::ArticleWriterSchema < RubyLLM::Schema
  CONTENT_DESCRIPTION = 'Full article body in clean Markdown. Use headings, lists, and code fences where appropriate. ' \
                        'Preserve steps, code samples, FAQs, troubleshooting detail. Strip marketing copy, navigation breadcrumbs, ' \
                        'social/share footers, "edit this page" links, repeated CTAs. ' \
                        'Total length must stay under 18000 characters; trim repetition and tangents before cutting substance.'.freeze
  TITLE_DESCRIPTION = 'Concise article title (max 80 chars). Plain text, no markdown.'.freeze
  DESCRIPTION_DESCRIPTION = 'One-sentence summary (max 200 chars) describing what the article teaches.'.freeze

  string :title, description: TITLE_DESCRIPTION, max_length: 80
  string :description, description: DESCRIPTION_DESCRIPTION, max_length: 200
  string :content, description: CONTENT_DESCRIPTION, max_length: 18_000
end
