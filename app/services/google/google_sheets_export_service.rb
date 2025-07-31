require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'

class Google::GoogleSheetsExportService # rubocop:disable Metrics/ClassLength
  def initialize(access_token, table_name, options = {})
    @access_token = access_token
    @table_name = table_name
    @options = options
    @sheets_service = Google::Apis::SheetsV4::SheetsService.new
    @drive_service = Google::Apis::DriveV3::DriveService.new
    setup_authorization
  end

  def export_to_sheets
    # Create new spreadsheet
    spreadsheet = create_spreadsheet
    # Get data from database table
    data = fetch_table_data
    # Write data to spreadsheet
    write_data_to_sheet(spreadsheet.spreadsheet_id, data)
    # Format the spreadsheet
    format_spreadsheet(spreadsheet.spreadsheet_id, data.first&.length || 0)
    {
      success: true,
      spreadsheet_id: spreadsheet.spreadsheet_id,
      spreadsheet_url: spreadsheet.spreadsheet_url,
      title: spreadsheet.properties.title,
      rows_exported: data.length - 1 # Subtract header row
    }
  rescue StandardError => e
    Rails.logger.error("Google Sheets export failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    {
      success: false,
      error: e.message
    }
  end

  private

  def setup_authorization
    @sheets_service.authorization = @access_token
    @drive_service.authorization = @access_token
  end

  def create_spreadsheet
    title = "#{@table_name.humanize} Export - #{Time.current.strftime('%Y-%m-%d %H:%M')}"

    spreadsheet = Google::Apis::SheetsV4::Spreadsheet.new(
      properties: Google::Apis::SheetsV4::SpreadsheetProperties.new(title: title)
    )

    @sheets_service.create_spreadsheet(spreadsheet)
  end

  def fetch_table_data
    model = get_model_class
    # Start with an empty relation and apply filters directly
    records = model.where(nil)
    # Apply filters if provided
    records = apply_filters(records) if @options[:filters].present?
    # Apply date filters if provided
    records = records.where('created_at >= ?', @options[:created_after]) if @options[:created_after].present?
    records = records.where('created_at <= ?', @options[:created_before]) if @options[:created_before].present?
    # Apply limit and offset if provided
    records = records.limit(@options[:limit]) if @options[:limit].present?
    records = records.offset(@options[:offset]) if @options[:offset].present?
    # Convert to array format for Google Sheets
    data = []
    # Add headers
    if records.any?
      headers = records.first.attributes.keys
      data << headers
      # Add data rows
      records.find_each do |record|
        row = headers.map { |header| format_cell_value(record.send(header)) }
        data << row
      end
    end
    data
  end

  def get_model_class
    case @table_name
    when 'conversations'
      Conversation
    when 'contacts'
      Contact
    when 'messages'
      Message
    when 'users'
      User
    when 'inboxes'
      Inbox
    when 'teams'
      Team
    when 'labels'
      Label
    when 'custom_attribute_definitions'
      CustomAttributeDefinition
    when 'webhooks'
      Webhook
    when 'campaigns'
      Campaign
    when 'canned_responses'
      CannedResponse
    when 'macros'
      Macro
    when 'categories'
      Category
    when 'articles'
      Article
    when 'automations'
      AutomationRule
    else
      raise ArgumentError, "Unknown table: #{@table_name}"
    end
  end

  def apply_filters(records)
    @options[:filters].each do |column, value|
      records = records.where(column => value)
    end
    records
  end

  def format_cell_value(value)
    case value
    when TrueClass, FalseClass
      value.to_s.capitalize
    when Hash, Array
      value.to_json
    when NilClass
      ''
    else
      value.to_s
    end
  end

  def write_data_to_sheet(spreadsheet_id, data)
    return if data.empty?

    range = "Sheet1!A1:#{column_letter(data.first.length)}#{data.length}"
    value_range = Google::Apis::SheetsV4::ValueRange.new(
      values: data
    )

    @sheets_service.update_spreadsheet_value(
      spreadsheet_id,
      range,
      value_range,
      value_input_option: 'RAW'
    )
  end

  def format_spreadsheet(spreadsheet_id, column_count)
    return if column_count.zero?

    requests = []

    # Format header row
    requests << {
      repeat_cell: {
        range: {
          sheet_id: 0,
          start_row_index: 0,
          end_row_index: 1,
          start_column_index: 0,
          end_column_index: column_count
        },
        cell: {
          user_entered_format: {
            background_color: {
              red: 0.9,
              green: 0.9,
              blue: 0.9
            },
            text_format: {
              bold: true
            }
          }
        },
        fields: 'userEnteredFormat(backgroundColor,textFormat)'
      }
    }

    # Auto-resize columns
    requests << {
      auto_resize_dimensions: {
        dimensions: {
          sheet_id: 0,
          dimension: 'COLUMNS',
          start_index: 0,
          end_index: column_count
        }
      }
    }

    # Freeze header row
    requests << {
      update_sheet_properties: {
        properties: {
          sheet_id: 0,
          grid_properties: {
            frozen_row_count: 1
          }
        },
        fields: 'gridProperties.frozenRowCount'
      }
    }

    batch_update_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: requests
    )

    @sheets_service.batch_update_spreadsheet(spreadsheet_id, batch_update_request)
  end

  def column_letter(column_number)
    result = ''
    while column_number.positive?
      column_number -= 1
      result = (65 + (column_number % 26)).chr + result
      column_number /= 26
    end
    result
  end

  def create_empty_spreadsheet(title = nil)
    title ||= "Data Export - #{Time.current.strftime('%Y-%m-%d %H:%M')}"

    spreadsheet = Google::Apis::SheetsV4::Spreadsheet.new(
      properties: Google::Apis::SheetsV4::SpreadsheetProperties.new(title: title)
    )

    result = @sheets_service.create_spreadsheet(spreadsheet)

    {
      success: true,
      spreadsheet_id: result.spreadsheet_id,
      spreadsheet_url: result.spreadsheet_url,
      title: result.properties.title
    }
  rescue StandardError => e
    Rails.logger.error("Failed to create empty spreadsheet: #{e.message}")
    {
      success: false,
      error: e.message
    }
  end
end
