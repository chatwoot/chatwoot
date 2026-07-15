class Captain::Llm::HelpCenterCurationSchema < RubyLLM::Schema
  CATEGORIES_DESCRIPTION = 'High-level categories that group the chosen articles. Use only as many ' \
                           'as the content naturally breaks into. Names must be short (1-3 words) and reusable.'.freeze
  ARTICLES_DESCRIPTION = 'A curated starting set of help-center articles selected from the input URL list. ' \
                         'Quality over quantity: only include pages with clear, high-value, substantive help ' \
                         'content. Skip blog posts, marketing/landing pages, login, pricing, legal, careers, ' \
                         'customer testimonials, press, about/company, whitepapers, support contact pages, ' \
                         'terms of service, privacy policy.'.freeze
  TITLE_DESCRIPTION = 'Concise article title (max 80 chars), rewritten if the source title is too long or marketing-y.'.freeze
  CATEGORY_DESCRIPTION = 'One sentence describing what kind of articles belong in this category.'.freeze
  URLS_DESCRIPTION = '1 to 3 source URLs from the input list. Prefer grouping when pages cover related ' \
                     'aspects of the same topic — overview + deep-dive, FAQ + how-to, policy + FAQ, ' \
                     'parent topic + its troubleshooting page. Merged sources give the writer more ' \
                     'context and produce stronger articles than several thin stubs.'.freeze

  array :categories, description: CATEGORIES_DESCRIPTION, min_items: 1, max_items: 10 do
    object do
      string :name, description: 'Short, human-readable category name (1-3 words).', max_length: 60
      string :description, description: CATEGORY_DESCRIPTION, max_length: 200
    end
  end

  array :articles, description: ARTICLES_DESCRIPTION, min_items: 1, max_items: 25 do
    object do
      array :urls, description: URLS_DESCRIPTION, min_items: 1, max_items: 3, of: :string
      string :title, description: TITLE_DESCRIPTION, max_length: 80
      string :category_name, description: 'Must exactly match one of the names emitted in the categories field.', max_length: 60
    end
  end
end
