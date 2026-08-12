class Captain::Routines::BuildEvaluation
  class << self
    def valid(summary)
      build(status: 'valid', summary: summary)
    end

    def correctable(summary, problems)
      corrections = problems.map do |problem|
        { 'path' => '/', 'problem' => problem, 'suggestion' => 'Compile this part again using the supplied DSL contract.' }
      end
      build(status: 'correctable', summary: summary, corrections: corrections)
    end

    def failed(error)
      build(status: 'failed', summary: error.to_s)
    end

    private

    def build(status:, summary:, corrections: [])
      {
        'status' => status,
        'summary' => summary,
        'corrections' => corrections,
        'questions' => [],
        'missing_capabilities' => []
      }
    end
  end
end
