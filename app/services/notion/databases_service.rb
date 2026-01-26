class Notion::DatabasesService
  def initialize(account)
    @account = account
    @hook = Integrations::Hook.where(account: account).find_by(app_id: 'notion')

    raise CustomExceptions::Notion::ApiError, 'Notion integration not found' unless @hook
    raise CustomExceptions::Notion::ApiError, 'Notion integration is not active' unless @hook.status == 'enabled'
  end

  # List all accessible data sources (databases)
  def list_databases
    response = client.post('/v1/search', {
      filter: { property: 'object', value: 'data_source' },
      page_size: 100
    })

    parse_databases(response['results'] || [])
  end

  # Get data source schema with properties
  def get_database_schema(database_id)
    response = client.get("/v1/data_sources/#{database_id}")

    {
      id: response['id'],
      title: extract_title(response['title']),
      url: response['url'],
      properties: parse_properties(response['properties'] || {})
    }
  end

  # Query database with optional filters
  def query_database(database_id, filters = {})
    body = {
      page_size: filters[:limit] || 100
    }

    # Build Notion filters from date_filters and select_filters
    notion_filters = build_notion_filters(filters)
    body[:filter] = notion_filters if notion_filters.present?

    body[:sorts] = [{ timestamp: 'created_time', direction: 'descending' }]

    response = client.post("/v1/data_sources/#{database_id}/query", body)

    parse_database_records(response['results'] || [])
  end

  private

  def client
    @client ||= Notion::ApiClient.new(@hook.access_token)
  end

  def parse_databases(results)
    results.map do |db|
      {
        id: db['id'],
        title: extract_title(db['title']),
        icon: db['icon'],
        url: db['url']
      }
    end
  end

  def parse_properties(properties)
    properties.map do |name, prop|
      {
        name: name,
        type: prop['type'],
        id: prop['id'],
        options: extract_property_options(prop)
      }
    end
  end

  def extract_property_options(property)
    case property['type']
    when 'select', 'multi_select'
      property[property['type']]['options']&.map do |opt|
        {
          id: opt['id'],
          name: opt['name'],
          color: opt['color']
        }
      end || []
    when 'date', 'number', 'phone_number', 'email'
      { type: property['type'] }
    else
      nil
    end
  end

  def extract_title(title_array)
    return 'Untitled' if title_array.blank?

    title_array.first&.dig('plain_text') || 'Untitled'
  end

  def parse_database_records(results)
    results.map do |record|
      {
        id: record['id'],
        created_time: record['created_time'],
        last_edited_time: record['last_edited_time'],
        url: record['url'],
        properties: record['properties']
      }
    end
  end

  def build_notion_filters(filter_params)
    return {} if filter_params.blank?

    filters = []

    # Process date filters
    if filter_params[:date_filters].present?
      filter_params[:date_filters].each do |date_filter|
        next unless date_filter[:field_name].present?

        case date_filter[:operator]
        when 'older_than'
          # Records older than X days (date before today - X days)
          target_date = (Time.zone.now - date_filter[:days].to_i.days).to_date.iso8601
          filters << {
            property: date_filter[:field_name],
            date: { before: target_date }
          }
        when 'newer_than'
          # Records newer than X days (date after today - X days)
          target_date = (Time.zone.now - date_filter[:days].to_i.days).to_date.iso8601
          filters << {
            property: date_filter[:field_name],
            date: { after: target_date }
          }
        when 'between'
          # Records between two dates - need two separate filters combined with 'and'
          if date_filter[:from_date].present? && date_filter[:to_date].present?
            filters << {
              property: date_filter[:field_name],
              date: { on_or_after: date_filter[:from_date] }
            }
            filters << {
              property: date_filter[:field_name],
              date: { on_or_before: date_filter[:to_date] }
            }
          end
        end
      end
    end

    # Process select filters
    if filter_params[:select_filters].present?
      filter_params[:select_filters].each do |select_filter|
        next unless select_filter[:field_name].present? && select_filter[:value].present?

        filters << {
          property: select_filter[:field_name],
          select: { equals: select_filter[:value] }
        }
      end
    end

    # Return empty hash if no filters, or wrap filters in 'and' operator
    return {} if filters.empty?

    # If only one filter, return it directly
    return filters.first if filters.length == 1

    # Multiple filters need to be wrapped in 'and'
    { and: filters }
  end
end
