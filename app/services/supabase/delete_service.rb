class Supabase::DeleteService < Supabase::BaseService
  base_uri "#{ENV.fetch('SUPABASE_URL', nil)}/rest/v1"

  def perform
    deleted
  end

  private

  def deleted
    table_name = options[:table_name]
    data = options[:data]

    response = self.class.delete(
      "/#{table_name}?id=eq.#{data[:id]}",
      headers: headers
    )

    Rails.logger.info("Deleting data from #{table_name}: #{data.to_json}")

    raise "Error deleting data from #{table_name}: #{response.code} #{response.message}" unless response.success?

    response.parsed_response
  rescue StandardError => e
    Rails.logger.error("❌ Failed to delete data from #{table_name}: #{e.message}")
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