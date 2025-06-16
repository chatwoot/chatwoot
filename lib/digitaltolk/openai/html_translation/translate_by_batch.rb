class Digitaltolk::Openai::HtmlTranslation::TranslateByBatch
  UNTRANSLATABLE_PARENT_NODES = %w[head style script].freeze

  def initialize(message, target_language)
    @message = message.reload
    @target_language = target_language
    @chunk_messages = []
  end

  def perform
    return if @message.blank?
    return if html_content.blank?

    batch_messages(extracted_chunks_from_html).each_with_index do |_chunk, index|
      Digitaltolk::Openai::HtmlTranslation::Translate.new.perform(@message, _chunk, @target_language, batch_index: index)
    end
  end

  private

  attr_reader :message

  def html_content
    @message.email.dig('html_content', 'full')
  end

  def extracted_chunks_from_html
    @chunk_messages = []
    doc = nokogiri_parsed_content

    doc.at('body').xpath('//text()').each do |node|
      text = node.text.strip
      next if text.blank?

      parent = node.parent
      next if UNTRANSLATABLE_PARENT_NODES.include?(parent.name)

      @chunk_messages << text
    end

    @chunk_messages
  end

  def nokogiri_parsed_content
    Nokogiri::HTML(html_content)
  end

  def batch_messages(chunks)
    Digitaltolk::Openai::HtmlTranslation::BatchByContentLength.perform(chunks)
  end
end
