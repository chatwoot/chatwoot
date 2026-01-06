class Captain::Onboarding::WebsiteAnalyzerService < Llm::BaseAiService
  include Integrations::LlmInstrumentation
  MAX_CONTENT_LENGTH = 8000

  def initialize(website_url)
    super()
    @website_url = normalize_url(website_url)
    @website_content = nil
    @favicon_url = nil
  end

  def analyze
    fetch_website_content
    return error_response('Failed to fetch website content') unless @website_content

    extract_business_info
  rescue StandardError => e
    Rails.logger.error "[Captain Onboarding] Website analysis error: #{e.message}"
    error_response(e.message)
  end

  private

  def normalize_url(url)
    return url if url.match?(%r{\Ahttps?://})

    "https://#{url}"
  end

  def fetch_website_content
    crawler = Captain::Tools::SimplePageCrawlService.new(@website_url)

    text_content = crawler.body_text_content
    page_title = crawler.page_title
    meta_description = crawler.meta_description

    if page_title.blank? && meta_description.blank? && text_content.blank?
      Rails.logger.error "[Captain Onboarding] Failed to fetch #{@website_url}: No content found"
      return false
    end

    combined_content = []
    combined_content << "Title: #{page_title}" if page_title.present?
    combined_content << "Description: #{meta_description}" if meta_description.present?
    combined_content << text_content

    @website_content = clean_and_truncate_content(combined_content.join("\n\n"))
    @favicon_url = crawler.favicon_url
    true
  rescue StandardError => e
    Rails.logger.error "[Captain Onboarding] Failed to fetch #{@website_url}: #{e.message}"
    false
  end

  def clean_and_truncate_content(content)
    cleaned = content.gsub(/\s+/, ' ').strip
    cleaned.length > MAX_CONTENT_LENGTH ? cleaned[0...MAX_CONTENT_LENGTH] : cleaned
  end

  def extract_business_info
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_params(response_format: { type: 'json_object' }, max_tokens: 1000)
        .with_temperature(0.1)
        .with_instructions(build_analysis_prompt)
        .ask(@website_content)
    end

    parse_llm_response(response.content)
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.website_analyzer',
      model: @model,
      temperature: 0.1,
      feature_name: 'website_analyzer',
      messages: [
        { role: 'system', content: build_analysis_prompt },
        { role: 'user', content: @website_content }
      ],
      metadata: { website_url: @website_url }
    }
  end

  def build_analysis_prompt
    <<~PROMPT
      Analyze the following website content and extract business information. Return a JSON response with the following structure:

      {
        "business_name": "The company or business name",
        "suggested_assistant_name": "A friendly assistant name (e.g., 'Captain Assistant', 'Support Genie', etc.)",
        "description": "Persona of the assistant based on the business type"
      }

      Guidelines:
      - business_name: Extract the actual company/brand name from the content
      - suggested_assistant_name: Create a friendly, professional name that customers would want to interact with
      - description: Provide context about the business and what the assistant can help with. Keep it general and adaptable rather than overly specific. For example: "You specialize in helping customers with their orders and product questions" or "You assist customers with their account needs and general inquiries"

      Website content:
      #{@website_content}

      Return only valid JSON, no additional text.
    PROMPT
  end

  def parse_llm_response(response_text)
    parsed_response = JSON.parse(response_text.strip)

    {
      success: true,
      data: {
        business_name: parsed_response['business_name'],
        suggested_assistant_name: parsed_response['suggested_assistant_name'],
        description: parsed_response['description'],
        website_url: @website_url,
        favicon_url: @favicon_url
      }
    }
  rescue JSON::ParserError => e
    Rails.logger.error "[Captain Onboarding] JSON parsing error: #{e.message}"
    Rails.logger.error "[Captain Onboarding] Raw response: #{response_text}"
    error_response('Failed to parse business information from website')
  end

  def error_response(message)
    {
      success: false,
      error: message,
      data: {
        business_name: '',
        suggested_assistant_name: '',
        description: '',
        website_url: @website_url,
        favicon_url: nil
      }
    }
  end
end
