class Supabase::UpdateService < Supabase::BaseService
  base_uri "#{ENV.fetch('SUPABASE_URL', nil)}/rest/v1"

  def perform
    updated
  end

  private

  def updated
    table_name = options[:table_name]
    data = options[:data]

    response = self.class.patch(
      "/#{table_name}?id=eq.#{data[:id]}",
      body: data.to_json,
      headers: headers
    )

    Rails.logger.info("Updating data in #{table_name}: #{data.to_json}")

    raise "Error updating data in #{table_name}: #{response.code} #{response.message}" unless response.success?

    response.parsed_response
  rescue StandardError => e
    Rails.logger.error("❌ Failed to update data in #{table_name}: #{e.message}")
    raise e
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'apikey' => ENV.fetch('SUPABASE_API_KEY', nil),
      'Authorization' => "Bearer #{ENV.fetch('SUPABASE_API_KEY', nil)}"
    }
  end
end
