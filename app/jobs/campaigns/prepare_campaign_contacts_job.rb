class Campaigns::PrepareCampaignContactsJob < ApplicationJob
  queue_as :low

  def perform(campaign)
    campaign.update!(contacts_preparation_status: :preparing)

    return unless campaign.audience.present?

    audience_label_ids = campaign.audience.select { |aud| aud['type'] == 'Label' }.pluck('id')
    if audience_label_ids.empty?
      campaign.update!(contacts_preparation_status: :prepared, total_contacts_count: 0, prepared_contacts_count: 0)
      return
    end

    labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    contacts = campaign.account.contacts.tagged_with(labels, any: true)
    total_count = contacts.count

    campaign.update!(total_contacts_count: total_count, prepared_contacts_count: 0)

    Rails.logger.info "Preparing #{total_count} campaign contacts for campaign #{campaign.id}"

    prepared_count = 0

    # Process in batches to avoid memory issues
    contacts.find_in_batches(batch_size: 500) do |batch|
      batch.each do |contact|
        campaign.campaign_contacts.find_or_create_by!(contact: contact)
        prepared_count += 1
      rescue ActiveRecord::RecordNotUnique
        # Contact already exists, skip
        prepared_count += 1
        next
      end

      # Update progress every batch
      campaign.update_column(:prepared_contacts_count, prepared_count)
    end

    campaign.update!(contacts_preparation_status: :prepared, prepared_contacts_count: total_count)
    Rails.logger.info "Finished preparing #{prepared_count}/#{total_count} campaign contacts for campaign #{campaign.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to prepare campaign contacts for campaign #{campaign.id}: #{e.message}"
    campaign.update!(contacts_preparation_status: :failed)
    raise e
  end
end
