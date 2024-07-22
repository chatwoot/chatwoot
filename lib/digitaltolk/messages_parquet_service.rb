require 'parquet'

class Digitaltolk::MessagesParquetService
  attr_accessor :messages, :file_name, :report

  def initialize(messages, file_name, report)
    @messages = messages
    @file_name = file_name
    @report = report
  end

  # @return [Hash]
  def perform
    process_upload
  end

  private

  def process_upload
    export_parquet
  rescue Exception => e
    Rails.logger.error "Error exporting parquet file: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    nil
  end

  def file_path
    @file_path ||= Rails.root.join('tmp', file_name)
  end

  def arrow_fields
    [
      Arrow::Field.new('id', :int32),
      Arrow::Field.new('content', :string),
      Arrow::Field.new('inbox_id', :int32),
      Arrow::Field.new('conversation_id', :int32),
      Arrow::Field.new('message_type', :string),
      Arrow::Field.new('content_type', :string),
      Arrow::Field.new('status', :string),
      Arrow::Field.new('created_at', :int32),
      Arrow::Field.new('private', :boolean),
      Arrow::Field.new('source_id', :int32)
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
    return if @messages.blank?

    batch_size = 1000
    index = 1
    GC.enable
    @messages.find_in_batches(batch_size: batch_size) do |message_batch|
      message_batch.each do |message|
        next if message.blank?
        @columns['id'] << message.id.to_i
        @columns['content'] << message.content.to_s
        @columns['inbox_id'] << message.inbox_id.to_i
        @columns['conversation_id'] << message.conversation.display_id.to_i
        @columns['message_type'] << message.message_type_before_type_cast.to_s
        @columns['content_type'] << message.content_type.to_s
        @columns['status'] << message.status.to_s
        @columns['created_at'] << message.created_at.to_i
        @columns['private'] << message.private
        @columns['source_id'] << message.source_id.to_i
      end
      report.update_columns(progress: (index * batch_size) / messages_count * 100)
      index += 1
      msgs = nil
      GC.start
    end
  end

  def messages_count
    @messages_count ||= @messages.count
  end

  def map_columns_array
    [
      Arrow::Int32Array.new(@columns['id']),
      Arrow::StringArray.new(@columns['content']),
      Arrow::Int32Array.new(@columns['inbox_id']),
      Arrow::Int32Array.new(@columns['conversation_id']),
      Arrow::StringArray.new(@columns['message_type']),
      Arrow::StringArray.new(@columns['content_type']),
      Arrow::StringArray.new(@columns['status']),
      Arrow::Int32Array.new(@columns['created_at']),
      Arrow::BooleanArray.new(@columns['private']),
      Arrow::Int32Array.new(@columns['source_id'])
    ]
  end

  def arrow_columns
    initialize_columns
    load_columns_data
    map_columns_array
  end

  def export_parquet
    record_batch = Arrow::RecordBatch.new(arrow_schema, @messages.count, arrow_columns)
    record_batch.to_table.save(file_path)

    url = Digitaltolk::UploadToS3.new(file_path).perform

    # Delete the file after upload
    File.delete(file_path) rescue nil
    url
  end
end
