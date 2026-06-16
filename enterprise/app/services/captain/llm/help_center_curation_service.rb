class Captain::Llm::HelpCenterCurationService < Captain::BaseTaskService
  RESPONSE_SCHEMA = Captain::Llm::HelpCenterCurationSchema
  MAX_LINKS_IN_PROMPT = 50
  IGNORED_URL_PATTERN = /\.(?:pdf|jpe?g|png|gif|webp|svg|ico|bmp|tiff?|avif|heic)(?:\?|#|$)/i
  # This model consistently outperforms 5.2 in generating tighter and more
  # accurate curations.
  CURATION_MODEL = 'gpt-4.1'.freeze

  pattr_initialize [:account!, :links!]

  def perform
    response = make_api_call(model: CURATION_MODEL, messages: messages, schema: RESPONSE_SCHEMA)
    return response if response[:error]

    response.merge(message: extract_payload(response[:message]))
  end

  private

  def extract_payload(message)
    return { categories: [], articles: [] } if message.blank?

    data = message.is_a?(Hash) ? message.deep_symbolize_keys : {}
    articles = Array(data[:articles])
    used_names = articles.map { |a| a[:category_name].to_s }
    categories = Array(data[:categories]).select { |c| used_names.include?(c[:name].to_s) }
    { categories: categories, articles: articles }
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ]
  end

  def system_prompt
    <<~PROMPT
      You are curating a help center for a company's customer-support widget.
      You will be given a list of pages discovered on the company's website.
      Pick pages that would make genuinely useful help-center articles for end users —
      substantive how-to, FAQ, troubleshooting, policy, getting-started, account/billing
      help, or product guide content.

      This is a STARTING SET for the user, not a comprehensive corpus. The user will add
      more articles later. Each article you pick costs downstream time, compute, and
      money to scrape and rewrite — be deliberate. Only include pages with clear,
      high-value, substantive help content. When unsure about a page's value, leave it
      out. 8 strong articles beat 20 padded ones, even when the input has 20+ candidates.

      Quality over quantity: do not pad with thin, overview, or marketing-adjacent pages
      to hit a target count. If a site has only a few genuinely useful pages, return only
      those few. The schema allows up to 25 articles, but treat that as a hard ceiling,
      not a target — most sites should land well under it.

      Skip marketing/landing pages, blog posts, login, pricing tiers, legal, careers, press, investor pages.
      Group your picks into reusable categories — use as many as the content naturally breaks into.
      Use the URL paths and page titles to judge relevance — do not invent URLs.

      URL-path priority (preference order, not hard rules):
        - First tier — almost always pick when present. Paths containing /support, /help,
          /docs, /documentation, /faq, /faqs, /kb, /knowledge-base, /learn, /guides,
          /getting-started, /how-to, /tutorial, /troubleshoot.
        - Second tier — pick when the page carries user-relevant information a customer
          would ask support about. Paths like /features, /pricing, /plans, /shipping,
          /returns, /warranty, /security, individual product or category pages. Prefer
          these only after first-tier picks; if a topic exists in both tiers, prefer the
          first-tier URL.
        - Skip — promotional, navigational, or boilerplate paths: /blog, /news, /press,
          /careers, /jobs, /about, /team, /investors, /customers, /testimonials,
          /case-studies, /login, /signup, /register, /legal, /terms, /privacy.

      For each article, group 1 to 3 URLs that together cover a single topic. PREFER
      grouping whenever pages overlap or complement each other — merged sources give
      the writer more context and produce a stronger article than two thin stubs.

      Strong signals to group multiple URLs (treat any of these as a green light):
        - Same topic from different angles: overview + deep-dive, FAQ + how-to,
          policy + FAQ, feature page + feature docs.
        - Parent topic + its troubleshooting page (e.g. "Bank reconciliation" +
          "Problems with bank reconciliation"; "SSO setup" + "SSO not working").
        - Variant-specific guides on the same topic ("SSO setup" + "SSO with Okta";
          "Webhooks overview" + "Webhook payload reference").
        - A how-to split across step or platform pages (install on iOS + Android + web).
        - FAQ entries that match a deep-dive article elsewhere on the site.

      Before finalizing your picks, scan them for merge candidates: if two URLs are
      about the same topic, they should almost always be one article, not two.

      Don't group across distinct topics that merely share a category ("Setting up SSO"
      and "Setting up MFA" stay separate). If a URL is marketing for a feature and
      another is the feature's docs, pick the docs and skip the marketing.

      Write all category names, category descriptions, and article titles in #{locale_name}.
      The input page titles and descriptions may be in another language; translate the labels you emit into #{locale_name}.
      Keep URLs unchanged.
    PROMPT
  end

  def user_prompt
    parts = [
      "Company: #{account.name}",
      ("Description: #{brand_info[:description]}" if brand_info[:description].present?),
      ("Industries: #{industries_text}" if industries_text.present?),
      'Discovered pages (url — title — description):',
      formatted_links
    ].compact
    parts.join("\n")
  end

  def locale_name
    code = account.locale.to_s
    LANGUAGES_CONFIG.values.find { |v| v[:iso_639_1_code] == code }&.dig(:name) || code.presence || 'English (en)'
  end

  def formatted_links
    Array(links).reject { |link| ignored_url?(link) }.first(MAX_LINKS_IN_PROMPT).map do |link|
      data = link.is_a?(Hash) ? link.deep_symbolize_keys : {}
      "- #{data[:url]} — #{data[:title].to_s.strip} — #{data[:description].to_s.strip}"
    end.join("\n")
  end

  def ignored_url?(link)
    url = link.is_a?(Hash) ? link.deep_symbolize_keys[:url].to_s : link.to_s
    url.match?(IGNORED_URL_PATTERN)
  end

  def brand_info
    @brand_info ||= (account.custom_attributes['brand_info'] || {}).deep_symbolize_keys
  end

  def industries_text
    Array(brand_info[:industries]).filter_map { |i| i.is_a?(Hash) ? i[:industry] : i }.join(', ').presence
  end

  def event_name
    'help_center_curation'
  end

  def llm_credential
    @llm_credential ||= system_llm_credential
  end

  def captain_tasks_enabled?
    true
  end

  # Onboarding curation runs on the operator's OpenAI key; it should not
  # debit the customer's captain_responses quota.
  def counts_toward_usage?
    false
  end

  def build_follow_up_context?
    false
  end
end
