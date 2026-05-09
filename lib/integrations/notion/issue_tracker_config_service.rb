class Integrations::Notion::IssueTrackerConfigService
  DATA_SOURCE_PATH = 'data_sources'.freeze

  pattr_initialize [:hook!]

  def validate(data_source_id)
    return { error: 'Data source is required' } if data_source_id.blank?

    response = notion_client.get("#{DATA_SOURCE_PATH}/#{data_source_id}")
    return { error: response[:error] } if response[:error]

    properties = normalized_properties(response[:properties])
    title_property = properties.find { |property| property[:type] == 'title' }
    return { error: 'Data source must include a title property' } if title_property.blank?

    {
      data: {
        data_source_id: response[:id] || data_source_id,
        title_property: title_property[:name],
        properties: properties
      }
    }
  end

  private

  def normalized_properties(properties)
    properties.to_h.map do |property_name, config|
      property = config.with_indifferent_access
      {
        name: property[:name].presence || property_name.to_s,
        type: property[:type]
      }
    end.sort_by { |property| property[:name].downcase }
  end

  def notion_client
    @notion_client ||= Notion::ApiClient.new(hook.access_token)
  end
end
