class Copilot::V2::RunSerializer
  PAGINATED_FIELDS = %w[rows selected_ids resolved_ids unresolved_ids unresolved].freeze

  def initialize(run, page: 1, per_page: 100)
    @run = run
    @page = page
    @per_page = per_page
  end

  def as_json(*) # rubocop:disable Metrics/AbcSize
    result = @run.structured_result.deep_dup
    (Array(result['results']) + result.fetch('datasets', {}).values).each do |projection|
      projection['pagination'] = {}
      PAGINATED_FIELDS.each do |field|
        next unless projection[field].is_a?(Array)

        values = projection[field]
        projection['pagination'][field] = { 'page' => @page, 'per_page' => @per_page, 'total' => values.size }
        offset = (@page - 1) * @per_page
        projection[field] = offset >= values.size ? [] : values.slice(offset, @per_page)
      end
    end
    result.merge('copilot_thread_id' => @run.copilot_thread_id, 'triggering_message_id' => @run.triggering_message_id,
                 'response_message_id' => @run.response_message_id, 'execution_availability' => @run.copilot_thread.execution_availability(run: @run))
  end
end
