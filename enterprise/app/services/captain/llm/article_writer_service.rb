class Captain::Llm::ArticleWriterService < Captain::BaseTaskService
  RESPONSE_SCHEMA = Captain::Llm::ArticleWriterSchema
  SOURCE_MAX_LENGTH = 60_000

  # source_pages: Array<{ url: String, markdown: String }>, 1-3 entries.
  pattr_initialize [:account!, :source_pages!, { hint_title: nil }]

  def perform
    response = make_api_call(model: writer_model, messages: messages, schema: RESPONSE_SCHEMA)
    return response if response[:error]

    response.merge(message: extract_payload(response[:message]))
  end

  private

  def extract_payload(message)
    return {} if message.blank?

    data = message.is_a?(Hash) ? message.deep_symbolize_keys : {}
    {
      title: data[:title].to_s.strip,
      description: data[:description].to_s.strip,
      content: data[:content].to_s.strip
    }
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ]
  end

  def system_prompt
    <<~PROMPT
      You are rewriting web page content into a clean help-center article for a customer-support knowledge base.
      You may receive 1 to 3 source pages. When given multiple sources, merge them into ONE coherent article:
      deduplicate identical instructions, do not repeat the same step in different words, and order content
      by the natural reading flow of the merged topic. When sources contradict, prefer the more authoritative
      or detailed version. The result must read like a single article, not a stitched-together collage.

      Preserve the substance: keep instructions, steps, code samples, configuration, troubleshooting, and FAQs intact.
      Strip marketing copy, navigation breadcrumbs, "share this page" footers, repeated CTAs, and links to unrelated pages.
      Output well-formatted Markdown — use headings, lists, and code fences where appropriate.
      The body must stay under 18000 characters. If the combined sources are longer, trim repetition and tangents
      before cutting steps or critical detail. Never invent content the sources do not support.

      Write the title, description, and body in #{locale_name}.
      If a source page is in another language, translate as you rewrite — do not copy source-language text into the output.
      Code samples, command-line examples, API field names, and proper nouns stay in their original form.
    PROMPT
  end

  def user_prompt
    pages = Array(source_pages).reject { |p| p[:markdown].to_s.blank? }
    per_source_cap = pages.size.positive? ? SOURCE_MAX_LENGTH / pages.size : SOURCE_MAX_LENGTH

    sections = pages.each_with_index.map do |page, idx|
      body = page[:markdown].to_s.truncate(per_source_cap, omission: "\n\n[source truncated for length]")
      "=== Source #{idx + 1} of #{pages.size} (#{page[:url]}) ===\n#{body}"
    end

    parts = [
      ("Suggested title (you may rewrite): #{hint_title}" if hint_title.present?),
      'Source pages (Markdown):',
      sections.join("\n\n")
    ].compact
    parts.join("\n\n")
  end

  def locale_name
    code = account.locale.to_s
    LANGUAGES_CONFIG.values.find { |v| v[:iso_639_1_code] == code }&.dig(:name) || code.presence || 'English (en)'
  end

  def event_name
    'article_writer'
  end

  def llm_credential
    @llm_credential ||= system_llm_credential
  end

  def captain_tasks_enabled?
    true
  end

  # Rewrite runs on the operator's OpenAI key during onboarding; should not
  # debit the customer's captain_responses quota.
  def counts_toward_usage?
    false
  end

  def writer_model
    'gpt-5.2'
  end

  def build_follow_up_context?
    false
  end
end
