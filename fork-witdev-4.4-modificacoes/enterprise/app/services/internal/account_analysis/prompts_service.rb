class Internal::AccountAnalysis::PromptsService
  class << self
    def threat_analyser(content)
      <<~PROMPT
        Analyze the following website content for potential security threats, scams, or illegal activities.

        Focus on identifying:
        1. Phishing attempts
        2. Fraudulent business practices
        3. Malware distribution
        4. Illegal product/service offerings
        5. Money laundering indicators
        6. Identity theft schemes

        Always classify websites under construction or without content to be a medium.

        Website content:
        #{content}

        Provide your analysis in the following JSON format:
        {
          "threat_level": "none|low|medium|high",
          "threat_summary": "Brief summary of findings",
          "detected_threats": ["threat1", "threat2"],
          "illegal_activities_detected": true|false,
          "recommendation": "approve|review|block"
        }
      PROMPT
    end
  end
end
