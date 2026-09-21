class Copilot::V2::Analyzer
  def initialize(runner)
    @runner = runner
    @run = runner.run
  end

  def process(key, source_key, manifest, specification) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    validator = Copilot::V2::ResultValidator.new(specification)
    if request_bytes([], specification, validator.schema) > Copilot::V2::Limits::REQUEST_BYTES
      raise ArgumentError, 'Analysis specification exceeds the request limit'
    end

    create_result(key, source_key, specification) unless @run.datasets.key?(key)
    pending = @run.copilot_run_items.where(dataset_key: key, state: 'pending').order(:position).limit(Copilot::V2::Limits::BATCH_SIZE).to_a
    if pending.empty?
      result = Copilot::V2::Results.new(@run).projection(key)
      return result.except('rows').merge('reference' => key)
    end

    batch = eligible_items(pending, manifest, specification, validator.schema)
    return if batch.empty?

    inputs = batch.map { |item| input(item) }
    begin
      response = @runner.provider_call(Copilot::V2::ChatService.analysis_payload(inputs, specification, validator.schema)) do
        @runner.commit! { batch.each { |item| item.update!(attempts: item.attempts + 1, supplied: true) } }
        @runner.client.analyze(inputs, specification, validator.schema)
      end
      output = response.content.is_a?(Hash) ? response.content : JSON.parse(response.content)
      results = validator.validate!(output, inputs)
      @runner.commit! do
        results.each do |row|
          item = batch.find { |candidate| candidate.evidence.fetch('id') == row.fetch('record_id') }
          begin
            @runner.resources.authorize_manifest!(manifest, item_ids: [item.evidence.fetch('id')])
            item.update!(state: 'resolved', result: row, reason: nil)
          rescue Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
            item.update!(state: 'unresolved', reason: 'record_unavailable')
          end
        end
      end
    rescue ArgumentError, JSON::ParserError, RubyLLM::Error, Timeout::Error
      @runner.commit! do
        batch.each do |item|
          item.update!(state: item.attempts >= Copilot::V2::Limits::ITEM_ATTEMPTS ? 'unresolved' : 'pending', reason: 'invalid_or_failed_analysis')
        end
      end
    end
    nil
  end

  private

  def create_result(key, source_key, specification)
    @runner.commit! do
      @run.copilot_run_items.where(dataset_key: source_key).order(:position).each do |source|
        @run.copilot_run_items.create!(dataset_key: key, resource_type: source.resource_type, resource_id: source.resource_id,
                                       position: source.position, source_item: source, state: source.state == 'captured' ? 'pending' : 'unresolved',
                                       reason: source.reason)
      end
      @run.update!(datasets: @run.datasets.merge(key => { 'reference_type' => 'result', 'source_ref' => source_key,
                                                          'resource' => @run.datasets.fetch(source_key).fetch('resource'),
                                                          'specification' => specification }))
    end
  end

  def eligible_items(pending, manifest, specification, schema)
    selected = []
    pending.each do |item|
      reason = eligibility_failure(item, manifest, specification, schema)
      if reason
        @runner.commit! { item.update!(state: 'unresolved', reason: reason) }
        next
      end
      break if request_bytes(selected.map { |member| input(member) } + [input(item)], specification, schema) > Copilot::V2::Limits::REQUEST_BYTES

      selected << item
    end
    selected
  end

  def eligibility_failure(item, manifest, specification, schema)
    return 'retry_budget' if item.attempts >= Copilot::V2::Limits::ITEM_ATTEMPTS
    return 'evidence_too_large' if request_bytes([input(item)], specification, schema) > Copilot::V2::Limits::REQUEST_BYTES

    @runner.resources.authorize_manifest!(manifest, item_ids: [item.evidence.fetch('id')])
    nil
  rescue Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
    'record_unavailable'
  end

  def request_bytes(inputs, specification, schema)
    Copilot::V2::ChatService.analysis_payload(inputs, specification, schema).to_json.bytesize + Copilot::V2::Limits::STATIC_PROMPT_BYTES
  end

  def input(item)
    captured = item.evidence
    records = captured.fetch('records').map do |record|
      next record if record.key?('parts')

      record.merge('parts' => if record['content'].present?
                                [{ 'id' => "record:#{record.fetch('id')}:content", 'text' => record['content'],
                                   'provenance' => 'stored_content' }]
                              else
                                []
                              end)
    end
    { 'record_id' => captured.fetch('id'), 'identity' => captured.fetch('identity', { 'id' => captured.fetch('id') }),
      'evidence' => records, 'limitations' => records.flat_map { |record| Array(record['limitations']) } }
  end
end
