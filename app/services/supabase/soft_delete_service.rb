class Supabase::SoftDeleteService < Supabase::BaseService
  base_uri "#{ENV.fetch('SUPABASE_URL', nil)}/rest/v1"

  def perform
    soft_deleted
  end

  private

  def soft_deleted
    table_name = options[:table_name]
    data = options[:data]

    response = self.class.patch(
      "/#{table_name}?id=eq.#{data[:id]}",
      body: { deleted_at: Time.now.utc.iso8601, is_deleted: true }.to_json,
      headers: headers
    )

    Rails.logger.info("Soft deleting data from #{table_name}: #{data.to_json}")

    raise "Error soft deleting data from #{table_name}: #{response.code} #{response.message}" unless response.success?

    response.parsed_response
  rescue StandardError => e
    Rails.logger.error("❌ Failed to soft delete data from #{table_name}: #{e.message}")
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
