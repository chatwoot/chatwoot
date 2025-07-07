class Supabase::InsertService < Supabase::BaseService
  base_uri "#{ENV.fetch('SUPABASE_URL', nil)}/rest/v1"

  def perform(table_name, data)
    insert(table_name, data)
  end

  private

  def insert(table_name, data)
    response = self.class.post(
      "/#{table_name}",
      body: data.to_json,
      headers: headers
    )

    Rails.logger.info("Inserting data into #{table_name}: #{data.to_json}")

    raise "Error inserting data into #{table_name}: #{response.code} #{response.message}" unless response.success?

    response.parsed_response
  rescue StandardError => e
    Rails.logger.error("❌ Failed to insert data into #{table_name}: #{e.message}")
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
