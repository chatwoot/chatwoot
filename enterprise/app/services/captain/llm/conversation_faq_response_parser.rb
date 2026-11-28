class Captain::Llm::ConversationFaqResponseParser
  def self.parse(response)
    payload = JSON.parse(response)
    raise TypeError, 'FAQ response must be an object' unless payload.is_a?(Hash)

    faqs = payload.fetch('faqs', [])
    raise TypeError, 'FAQs must be an array of questions and answers' unless faqs.is_a?(Array) && faqs.all? { |faq| valid_faq?(faq) }

    faqs
  end

  def self.valid_faq?(faq)
    faq.is_a?(Hash) && %w[question answer].all? { |field| faq[field].is_a?(String) && faq[field].present? }
  end

  private_class_method :valid_faq?
end
