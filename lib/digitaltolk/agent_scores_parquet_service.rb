require 'parquet'

class Digitaltolk::AgentScoresParquetService
  attr_accessor :agent_scores, :file_name, :report

  def initialize(agent_scores, file_name, report)
    @agent_scores = agent_scores
    @file_name = file_name
    @report = report
  end

  # @return [Hash]
  def perform
    report.in_progress!(record_count: record_count)
    export_parquet
  rescue StandardError => e
    report.failed!("#{e.message}: #{e.backtrace.first}")
    nil
  end

  def file_path
    @file_path ||= Rails.root.join('tmp', file_name)
  end

  private

  def arrow_fields
    [
      Arrow::Field.new('id', :int64),
      Arrow::Field.new('active', :boolean),
      Arrow::Field.new('message_id', :int64),
      Arrow::Field.new('conversation_id', :int64),
      Arrow::Field.new("score", :string),
      Arrow::Field.new('criteria', :string),
      Arrow::Field.new('agent_id', :int64),
      Arrow::Field.new('agent_name', :string),
      Arrow::Field.new('created_at', :int64),
    ]
  end

  def arrow_schema
    Arrow::Schema.new(arrow_fields)
  end

  def initialize_columns
    @columns = {}

    arrow_fields.each do |f|
      @columns[f.name] = []
    end
  end

  def load_columns_data
    return if agent_scores.is_a?(Array) && agent_scores.blank?
    return unless agent_scores.exists?

    index = 1
    batch_size = 100
    GC.enable

    agent_scores.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |agent_score|
        @columns['id'] << agent_score.id
        @columns['active'] << agent_score.active
        @columns['message_id'] << agent_score.message_id
        @columns['conversation_id'] << agent_score.conversation_id
        @columns['score'] << agent_score.score.to_s
        @columns['criteria'] << agent_score.criteria.to_json
        @columns['agent_id'] << agent_score.message.sender_id
        @columns['agent_name'] << agent_score.message.sender&.name
        @columns['created_at'] << agent_score.created_at.to_i
      end

      report.in_progress!(record_count: index * batch_size)
      index += 1
      batch = nil
      GC.start
    end
  end

  def record_count
    (@record_count ||= agent_scores.count).to_i
  end

  def map_columns_array
    [
      Arrow::Int64Array.new(@columns['id']),
      Arrow::BooleanArray.new(@columns['active']),
      Arrow::Int64Array.new(@columns['message_id']),
      Arrow::Int64Array.new(@columns['conversation_id']),
      Arrow::StringArray.new(@columns['score']),
      Arrow::StringArray.new(@columns['criteria']),
      Arrow::Int64Array.new(@columns['agent_id']),
      Arrow::StringArray.new(@columns['agent_name']),
      Arrow::Int64Array.new(@columns['created_at']),
    ]
  end

  def arrow_columns
    initialize_columns
    load_columns_data
    map_columns_array
  end

  def export_parquet
    record_batch = Arrow::RecordBatch.new(arrow_schema, record_count, arrow_columns)
    record_batch.to_table.save(file_path)

    url = Digitaltolk::UploadToS3.new(file_path).perform
    File.delete(file_path) rescue nil
    url
  end
end
