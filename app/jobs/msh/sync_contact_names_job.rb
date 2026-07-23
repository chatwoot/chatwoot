# Renames Coro Inbox contacts to "Pet(s) — Owner" using the MSH
# (admin-essentials) customer database, so receptionists see who a chat
# belongs to directly in the conversation list.
class Msh::SyncContactNamesJob < ApplicationJob
  queue_as :low

  ENDPOINT = 'https://admin-essentials.vercel.app/api/coro-contact-names'.freeze
  BATCH_SIZE = 500

  def perform(account_id = 4)
    token = ENV.fetch('CORO_PANEL_TOKEN')
    account = Account.find(account_id)

    account.contacts.where.not(phone_number: [nil, '']).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      results = fetch_names(token, batch.map(&:phone_number))
      batch.each do |contact|
        desired = desired_name(results[contact.phone_number])
        contact.update(name: desired) if desired.present? && contact.name != desired
      end
    end
  end

  private

  def fetch_names(token, phones)
    response = HTTParty.post(
      "#{ENDPOINT}?token=#{token}",
      headers: { 'Content-Type' => 'application/json' },
      body: { phones: phones }.to_json
    )
    raise "coro-contact-names request failed: #{response.code} #{response.body&.first(200)}" unless response.success?

    response.parsed_response['results'] || {}
  end

  def desired_name(info)
    return nil if info.blank?

    owner = info['ownerName'].presence
    return nil if owner.blank?

    pets = Array(info['petNames']).map(&:presence).compact
    pets.any? ? "#{pets.join(' & ')} — #{owner}" : owner
  end
end
